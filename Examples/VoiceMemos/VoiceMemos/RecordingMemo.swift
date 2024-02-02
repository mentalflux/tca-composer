import ComposableArchitecture
import SwiftUI
import TCAComposer

@Composer
struct RecordingMemo {
  struct State: Equatable, Sendable {
    var date: Date
    var duration: TimeInterval = 0
    var mode: Mode = .recording
    var url: URL

    enum Mode {
      case recording
      case encoding
    }
  }

  struct Failed: Equatable, Error {}

  enum Actions {
    @ComposeActionCase
    enum Delegate: Sendable {
      case didFinish(Result<State, Error>)
    }

    enum Effect {
      case audioRecorderDidFinish(Result<Bool, Error>)
      case finalRecordingTime(TimeInterval)
      case timerUpdated
    }

    enum View {
      case onTask
      case stopButtonTapped
    }
  }

  @Dependency(\.audioRecorder) var audioRecorder
  @Dependency(\.continuousClock) var clock

  @ComposeBodyActionCase
  func effect(state: inout State, action: Actions.Effect) -> EffectOf<Self> {
    switch action {
    case .audioRecorderDidFinish(.success(true)):
      return .send(.delegate(.didFinish(.success(state))))

    case .audioRecorderDidFinish(.success(false)):
      return .send(.delegate(.didFinish(.failure(Failed()))))

    case let .audioRecorderDidFinish(.failure(error)):
      return .send(.delegate(.didFinish(.failure(error))))

    case let .finalRecordingTime(duration):
      state.duration = duration
      return .none

    case .timerUpdated:
      state.duration += 1
      return .none
    }
  }

  @ComposeBodyActionCase
  func view(state: inout State, action: Actions.View) -> EffectOf<Self> {
    switch action {
    case .stopButtonTapped:
      state.mode = .encoding
      return .run { send in
        if let currentTime = await self.audioRecorder.currentTime() {
          await send(.effect(.finalRecordingTime(currentTime)))
        }
        await self.audioRecorder.stopRecording()
      }

    case .onTask:
      return .run { [url = state.url] send in
        async let startRecording: Void = send(
          .effect(
            .audioRecorderDidFinish(
              Result { try await self.audioRecorder.startRecording(url: url) }
            ))
        )
        for await _ in self.clock.timer(interval: .seconds(1)) {
          await send(.effect(.timerUpdated))
        }
        await startRecording
      }
    }
  }
}

@ViewAction(for: RecordingMemo.self)
struct RecordingMemoView: View {
  @Bindable var store: StoreOf<RecordingMemo>

  var body: some View {
    VStack(spacing: 12) {
      Text("Recording")
        .font(.title)
        .colorMultiply(Color(Int(store.duration).isMultiple(of: 2) ? .systemRed : .label))
        .animation(.easeInOut(duration: 0.5), value: store.duration)

      if let formattedDuration = dateComponentsFormatter.string(from: store.duration) {
        Text(formattedDuration)
          .font(.body.monospacedDigit().bold())
          .foregroundColor(.black)
      }

      ZStack {
        Circle()
          .foregroundColor(Color(.label))
          .frame(width: 74, height: 74)

        Button {
          send(.stopButtonTapped, animation: .default)
        } label: {
          RoundedRectangle(cornerRadius: 4)
            .foregroundColor(Color(.systemRed))
            .padding(17)
        }
        .frame(width: 70, height: 70)
      }
    }
    .task {
      await send(.onTask).finish()
    }
  }
}
