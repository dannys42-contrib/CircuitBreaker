/**
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation

/// Invocation entity
public class Invocation<A, B, C> {
  
  /// Arguments for circuit command
  public let commandArgs: A

  /// Timeout state of invocation
  private(set) var timedOut: Bool = false

  /// Completion state of invocation
  private(set) var completed: Bool = false

  weak private var breaker: CircuitBreaker<A, B, C>?

  /// Invocation Initializer
  /// - Parameters:
  ///   - breaker CircuitBreaker Instance
  ///   - commandArgs Arguments for command context
  ///
  public init(breaker: CircuitBreaker<A, B, C>, commandArgs: A) {
    self.commandArgs = commandArgs
    self.breaker = breaker
  }

  /// Marks invocation as having timed out
  public func setTimedOut() {
    self.timedOut = true
  }

  /// Marks invocation as completed
  public func setCompleted() {
    self.completed = true
  }

  /// Notifies the circuit breaker of success if a timeout has not occurred
  public func notifySuccess() {
    if !self.timedOut {
      self.setCompleted()
      breaker?.notifySuccess()
    }
  }
 
  /// Notifies the circuit breaker of success if a timeout has not alreadt occurred
  public func notifyFailure() {
    if !self.timedOut {
      self.setCompleted()
      breaker?.notifyFailure()
    }
  }
}