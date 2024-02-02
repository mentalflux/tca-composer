import AVFoundation
import ComposableArchitecture
import SwiftUI
import TCAComposer

@ComposeReducer(
  children: [
    .presentsAlert(),
    .presentsReducer("recordingMemo", of: RecordingMemo.self),
    .identifiedArray("voiceMemos", of: VoiceMemo.self),
  ]
)
@Composer
struct VoiceMemos {
  struct State: Equatable {
    var audioRecorderPermission = RecorderPermission.undetermined

    enum RecorderPermission {
      case allowed
      case denied
      case undetermined
    }
  }

  enum Actions {
    enum Effect {
      case recordPermissionResponse(Bool)
    }

    enum View {
      case onDelete(IndexSet)
      case openSettingsButtonTapped
      case recordButtonTapped
    }
  }

  @Dependency(\.audioRecorder.requestRecordPermission) var requestRecordPermission
  @Dependency(\.date) var date
  @Dependency(\.openSettings) var openSettings
  @Dependency(\.temporaryDirectory) var temporaryDirectory
  @Dependency(\.uuid) var uuid

  @ComposeBodyActionCase
  func effect(state: inout State, action: Actions.Effect) -> EffectOf<Self> {
    switch action {
    case let .recordPermissionResponse(permission):
      state.audioRecorderPermission = permission ? .allowed : .denied
      if permission {
        state.recordingMemo = newRecordingMemo
        return .none
      } else {
        state.alert = AlertState { TextState("Permission is required to record voice memos.") }
        return .none
      }
    }
  }

  @ComposeBody(
    identifiedAction: \Action.Cases.voiceMemos,
    elementAction: \.delegate
  )
  func handleVoiceMemoDelegate(
    state: inout State, id: VoiceMemo.State.ID, action: VoiceMemo.Actions.Delegate
  ) {
    switch action {
    case .playbackFailed:
      state.alert = AlertState { TextState("Voice memo playback failed.") }
    case .playbackStarted:
      for memoID in state.voiceMemos.ids where memoID != id {
        state.voiceMemos[id: memoID]?.mode = .notPlaying
      }
    }
  }

  @ComposeBody(action: \Action.Cases.recordingMemo.presented.delegate.didFinish.success)
  func onRecordingMemoDidFinish(state: inout State, action recordingMemo: RecordingMemo.State) {
    state.recordingMemo = nil
    state.voiceMemos.insert(
      VoiceMemo.State(
        date: recordingMemo.date,
        duration: recordingMemo.duration,
        url: recordingMemo.url
      ),
      at: 0
    )
  }

  @ComposeBody(action: \Action.Cases.recordingMemo.presented.delegate.didFinish.failure)
  func onRecordingMemoDidFinishFailure(state: inout State) {
    state.alert = AlertState { TextState("Voice memo recording failed.") }
    state.recordingMemo = nil
  }

  @ComposeBodyActionCase
  func view(state: inout State, action: Actions.View) -> EffectOf<Self> {
    switch action {
    case let .onDelete(indexSet):
      state.voiceMemos.remove(atOffsets: indexSet)
      return .none

    case .openSettingsButtonTapped:
      return .run { _ in
        await self.openSettings()
      }

    case .recordButtonTapped:
      switch state.audioRecorderPermission {
      case .undetermined:
        return .run { send in
          await send(.effect(.recordPermissionResponse(self.requestRecordPermission())))
        }

      case .denied:
        state.alert = AlertState { TextState("Permission is required to record voice memos.") }
        return .none

      case .allowed:
        state.recordingMemo = newRecordingMemo
        return .none
      }

    }
  }

  private var newRecordingMemo: RecordingMemo.State {
    RecordingMemo.State(
      date: self.date.now,
      url: self.temporaryDirectory()
        .appendingPathComponent(self.uuid().uuidString)
        .appendingPathExtension("m4a")
    )
  }
}

@ViewAction(for: VoiceMemos.self)
struct VoiceMemosView: View {
  @Bindable var store: StoreOf<VoiceMemos>

  var body: some View {
    NavigationStack {
      VStack {
        List {
          ForEach(store.scopes.voiceMemos) { store in
            VoiceMemoView(store: store)
          }
          .onDelete { send(.onDelete($0)) }
        }

        Group {
          if let store = store.scopes.recordingMemo {
            RecordingMemoView(store: store)
          } else {
            RecordButton(permission: store.audioRecorderPermission) {
              send(.recordButtonTapped, animation: .spring())
            } settingsAction: {
              send(.openSettingsButtonTapped)
            }
          }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.init(white: 0.95))
      }
      .alert($store.scopes(\.alert))
      .navigationTitle("Voice memos")
    }
  }
}

struct RecordButton: View {
  let permission: VoiceMemos.State.RecorderPermission
  let action: () -> Void
  let settingsAction: () -> Void

  var body: some View {
    ZStack {
      Group {
        Circle()
          .foregroundColor(Color(.label))
          .frame(width: 74, height: 74)

        Button(action: action) {
          RoundedRectangle(cornerRadius: 35)
            .foregroundColor(Color(.systemRed))
            .padding(2)
        }
        .frame(width: 70, height: 70)
      }
      .opacity(permission == .denied ? 0.1 : 1)

      if permission == .denied {
        VStack(spacing: 10) {
          Text("Recording requires microphone access.")
            .multilineTextAlignment(.center)
          Button("Open Settings", action: settingsAction)
        }
        .frame(maxWidth: .infinity, maxHeight: 74)
      }
    }
  }
}

#Preview {
  VoiceMemosView(
    store: Store(
      initialState: VoiceMemos.State(
        voiceMemos: [
          VoiceMemo.State(
            date: Date(),
            duration: 5,
            mode: .notPlaying,
            title: "Functions",
            url: URL(string: "https://www.pointfree.co/functions")!
          ),
          VoiceMemo.State(
            date: Date(),
            duration: 5,
            mode: .notPlaying,
            title: "",
            url: URL(string: "https://www.pointfree.co/untitled")!
          ),
        ]
      )
    ) {
      VoiceMemos()
    }
  )
}
