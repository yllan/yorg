//
//  YIApplication.swift
//  yorg
//
//  Created by Yung-Luen Lan on 2018/11/8.
//  Copyright © 2018 yllan. All rights reserved.
//

import Foundation
import Dispatch

#if os(Linux)
import Glibc
import CNCURSES
#else
import Darwin
import Darwin.ncurses
import Darwin.POSIX.termios
import Darwin.POSIX.unistd
import Darwin.POSIX.fcntl
#endif

// row, col
func windowSize() -> (Int, Int) {
    let size = UnsafeMutablePointer<winsize>.allocate(capacity: 1)
    let _ = ioctl(STDIN_FILENO, TIOCGWINSZ, size)
    return (Int(size.pointee.ws_row), Int(size.pointee.ws_col))
}

enum Event {
    case resize(Int, Int) // row, col
    case input(String)
    case keyUp
    case keyDown
    case keyLeft
    case keyRight
    case ctrl(Int)
}

class YIApplication {
    
    let windowSource = DispatchSource.makeSignalSource(signal: SIGWINCH, queue: DispatchQueue.main)
    var eventQueue: [Event] = []
    var originalTermios: termios = termios()
    var shouldTerminate: Bool = false
    
    func enableRawMode() {
        let term = UnsafeMutablePointer<termios>.allocate(capacity: 1)
        tcgetattr(STDIN_FILENO, term)
        term.pointee.c_lflag &= ~UInt(ECHO)    // turn-off echo
        term.pointee.c_lflag &= ~UInt(ICANON)  // turn-off buffering
        term.pointee.c_lflag &= ~UInt(ISIG)    // turn-off ^C, ^Y, ^Z
        term.pointee.c_lflag &= ~UInt(IEXTEN)  // turn-off ^V
        term.pointee.c_iflag &= ~UInt(IXON)    // turn-off ^S, ^Q
        term.pointee.c_iflag &= ~UInt(ICRNL)   // turn-off ^M
        term.pointee.c_oflag &= ~UInt(OPOST)   // turn-off translating \n -> \r\n
        tcsetattr(STDIN_FILENO, TCSANOW, term)
    }

    init() {
        tcgetattr(STDIN_FILENO, &originalTermios)
        
        // setup the terminal (turn off echo, etc.)
        enableRawMode()
        
        // make the input non-blocking
        let f = fcntl(STDIN_FILENO, F_GETFL, 0)
        _ = fcntl(STDIN_FILENO, F_SETFL, f | O_NONBLOCK)
        
        print("\(windowSize())")
        
        windowSource.setEventHandler {
            let (row, col) = windowSize()
            print(row, col)
            self.eventQueue.append(Event.resize(row, col))
        }
        windowSource.resume()
    }
    
    var unparsedBytes: [UInt8] = []
    
    func receiveKeyEvent() -> String? {
        let bufSize = 1024
        let buf = UnsafeMutablePointer<UInt8>.allocate(capacity: bufSize)
        let readCount = read(STDIN_FILENO, buf, 1024)
        if readCount == -1 && errno == EAGAIN {
            return nil
        } else {
            let code: [UInt8] = Array(0..<readCount).map { (buf + $0).pointee }
            print(code.map{"\($0)"}.joined(separator: ","))
            // parsing
            
            return String(bytesNoCopy: buf, length: readCount, encoding: .utf8, freeWhenDone: true)
        }
    }
    
    func run() {
        applicationWillLaunch()
        
        let delta = 1.0 / 60.0
        while !shouldTerminate {
            RunLoop.main.acceptInput(forMode: RunLoop.Mode.default, before: Date(timeIntervalSinceNow: delta))
            
            // process key event
            if let input = receiveKeyEvent() {
                if input == "q" {
                    self.terminate()
                }
            }
            
            // TODO: feed event to application
            
        }
        
        // clean up
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &originalTermios)
        
        applicationWillTerminate()
    }
    
    func applicationWillLaunch() {
        
    }
    
    func applicationWillTerminate() {
        
    }
    
    func terminate() {
        self.shouldTerminate = true
    }
}
