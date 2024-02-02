import ComposableArchitecture
import SwiftUI
import TCAComposer

@ComposeReducer(
  children: [
    .presentsDestination(
      children: [
        .alert(),
        .reducer("edit", of: SyncUpForm.self),
      ]
    )
  ]
)
@Composer
struct SyncUpDetail {
  struct State: Equatable {
    var syncUp: SyncUp

    init(destination: Destination.State? = nil, syncUp: SyncUp) {
      self.destination = destination
      self.syncUp = syncUp
    }
  }

  enum Actions {
    enum Alert {
      case confirmDeletion
      case continueWithoutRecording
      case openSettings
    }

    @ComposeActionCase
    enum Delegate {
      case deleteSyncUp
      case syncUpUpdated(SyncUp)
      case startMeeting
    }

    enum View {
      case cancelEditButtonTapped
      case deleteButtonTapped
      case deleteMeetings(atOffsets: IndexSet)
      case doneEditingButtonTapped
      case editButtonTapped
      case startMeetingButtonTapped
    }
  }

  @Dependency(\.dismiss) var dismiss
  @Dependency(\.openSettings) var openSettings
  @Dependency(\.speechClient.authorizationStatus) var authorizationStatus

  @ComposeBodyActionAlertCase
  func handleAlert(action: Actions.Alert) -> EffectOf<Self> {
    switch action {
    case .confirmDeletion:
      return .run { send in
        await send(.delegate(.deleteSyncUp), animation: .default)
        await self.dismiss()
      }
    case .continueWithoutRecording:
      return .send(.delegate(.startMeeting))
    case .openSettings:
      return .run { _ in
        await self.openSettings()
      }
    }
  }

  @ComposeBodyOnChange(of: \State.syncUp)
  func onChangeOfSyncUp(newValue: SyncUp) -> EffectOf<Self> {
    .send(.delegate(.syncUpUpdated(newValue)))
  }

  @ComposeBodyActionCase
  func view(state: inout State, action: Actions.View) -> EffectOf<Self> {
    switch action {
    case .cancelEditButtonTapped:
      state.destination = nil
      return .none

    case .deleteButtonTapped:
      state.destination = .alert(.deleteSyncUp)
      return .none

    case let .deleteMeetings(atOffsets: indices):
      state.syncUp.meetings.remove(atOffsets: indices)
      return .none

    case .doneEditingButtonTapped:
      guard case let .some(.edit(editState)) = state.destination
      else { return .none }
      state.syncUp = editState.syncUp
      state.destination = nil
      return .none

    case .editButtonTapped:
      state.destination = .edit(SyncUpForm.State(syncUp: state.syncUp))
      return .none

    case .startMeetingButtonTapped:
      switch self.authorizationStatus() {
      case .notDetermined, .authorized:
        return .send(.delegate(.startMeeting))

      case .denied:
        state.destination = .alert(.speechRecognitionDenied)
        return .none

      case .restricted:
        state.destination = .alert(.speechRecognitionRestricted)
        return .none

      @unknown default:
        return .none
      }
    }
  }
}

@ViewAction(for: SyncUpDetail.self)
struct SyncUpDetailView: View {
  @Bindable var store: StoreOf<SyncUpDetail>

  var body: some View {
    Form {
      Section {
        Button {
          send(.startMeetingButtonTapped)
        } label: {
          Label("Start Meeting", systemImage: "timer")
            .font(.headline)
            .foregroundColor(.accentColor)
        }
        HStack {
          Label("Length", systemImage: "clock")
          Spacer()
          Text(store.syncUp.duration.formatted(.units()))
        }

        HStack {
          Label("Theme", systemImage: "paintpalette")
          Spacer()
          Text(store.syncUp.theme.name)
            .padding(4)
            .foregroundColor(store.syncUp.theme.accentColor)
            .background(store.syncUp.theme.mainColor)
            .cornerRadius(4)
        }
      } header: {
        Text("Sync-up Info")
      }

      if !store.syncUp.meetings.isEmpty {
        Section {
          ForEach(store.syncUp.meetings) { meeting in
            NavigationLink(
              state: AppFeature.Path.State.meeting(meeting, syncUp: store.syncUp)
            ) {
              HStack {
                Image(systemName: "calendar")
                Text(meeting.date, style: .date)
                Text(meeting.date, style: .time)
              }
            }
          }
          .onDelete { indices in
            send(.deleteMeetings(atOffsets: indices))
          }
        } header: {
          Text("Past meetings")
        }
      }

      Section {
        ForEach(store.syncUp.attendees) { attendee in
          Label(attendee.name, systemImage: "person")
        }
      } header: {
        Text("Attendees")
      }

      Section {
        Button("Delete") {
          send(.deleteButtonTapped)
        }
        .foregroundColor(.red)
        .frame(maxWidth: .infinity)
      }
    }
    .toolbar {
      Button("Edit") {
        send(.editButtonTapped)
      }
    }
    .navigationTitle(store.syncUp.title)
    .alert($store.scopes(\.destination.alert))
    .sheet(item: $store.scopes(\.destination.edit)) { store in
      NavigationStack {
        SyncUpFormView(store: store)
          .navigationTitle(self.store.syncUp.title)
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Cancel") {
                send(.cancelEditButtonTapped)
              }
            }
            ToolbarItem(placement: .confirmationAction) {
              Button("Done") {
                send(.doneEditingButtonTapped)
              }
            }
          }
      }
    }
  }
}

extension AlertState where Action == SyncUpDetail.Actions.Alert {
  static let deleteSyncUp = Self {
    TextState("Delete?")
  } actions: {
    ButtonState(role: .destructive, action: .confirmDeletion) {
      TextState("Yes")
    }
    ButtonState(role: .cancel) {
      TextState("Nevermind")
    }
  } message: {
    TextState("Are you sure you want to delete this meeting?")
  }

  static let speechRecognitionDenied = Self {
    TextState("Speech recognition denied")
  } actions: {
    ButtonState(action: .continueWithoutRecording) {
      TextState("Continue without recording")
    }
    ButtonState(action: .openSettings) {
      TextState("Open settings")
    }
    ButtonState(role: .cancel) {
      TextState("Cancel")
    }
  } message: {
    TextState(
      """
      You previously denied speech recognition and so your meeting will not be recorded. You can \
      enable speech recognition in settings, or you can continue without recording.
      """
    )
  }

  static let speechRecognitionRestricted = Self {
    TextState("Speech recognition restricted")
  } actions: {
    ButtonState(action: .continueWithoutRecording) {
      TextState("Continue without recording")
    }
    ButtonState(role: .cancel) {
      TextState("Cancel")
    }
  } message: {
    TextState(
      """
      Your device does not support speech recognition and so your meeting will not be recorded.
      """
    )
  }
}

#Preview {
  NavigationStack {
    SyncUpDetailView(
      store: Store(initialState: SyncUpDetail.State(syncUp: .mock)) {
        SyncUpDetail()
      }
    )
  }
}
