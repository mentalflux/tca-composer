import ComposableArchitecture
import SwiftUI
import TCAComposer

@ComposeReducer(
  children: [
    .navigationStack(
      children: [
        .reducer("detail", of: SyncUpDetail.self),
        .state("meeting", of: (Meeting, syncUp: SyncUp).self),
        .reducer("record", of: RecordMeeting.self),
      ]
    ),
    .reducer("syncUpsList", of: SyncUpsList.self, initialState: .init()),
  ]
)
@Composer
struct AppFeature {
  @Dependency(\.continuousClock) var clock
  @Dependency(\.date.now) var now
  @Dependency(\.dataManager.save) var saveData
  @Dependency(\.uuid) var uuid

  private enum CancelID {
    case saveDebounce
  }

  @ComposeBody(action: \Action.Cases.path)
  func path(state: inout State, action: StackAction<Path.State, Path.Action>) {
    switch action {
    case let .element(id, .detail(.delegate(delegateAction))):
      guard case let .some(.detail(detailState)) = state.path[id: id]
      else { return }

      switch delegateAction {
      case .deleteSyncUp:
        state.syncUpsList.syncUps.remove(id: detailState.syncUp.id)

      case let .syncUpUpdated(syncUp):
        state.syncUpsList.syncUps[id: syncUp.id] = syncUp

      case .startMeeting:
        state.path.append(.record(RecordMeeting.State(syncUp: detailState.syncUp)))
      }

    case let .element(_, .record(.delegate(delegateAction))):
      switch delegateAction {
      case let .save(transcript: transcript):
        guard let id = state.path.ids.dropLast().last
        else {
          XCTFail(
            """
            Record meeting is the only element in the stack. A detail feature should precede it.
            """
          )
          return
        }

        state.path[id: id, case: \.detail]?.syncUp.meetings.insert(
          Meeting(
            id: Meeting.ID(self.uuid()),
            date: self.now,
            transcript: transcript
          ),
          at: 0
        )
        guard let syncUp = state.path[id: id, case: \.detail]?.syncUp
        else { return }
        state.syncUpsList.syncUps[id: syncUp.id] = syncUp
      }

    default:
      return

    }
  }

  @ComposeBody(position: .afterCore)
  func saveSyncUps(state: State) -> EffectOf<Self> {
    .run { _ in
      try await withTaskCancellation(id: CancelID.saveDebounce, cancelInFlight: true) {
        try await self.clock.sleep(for: .seconds(1))
        try await self.saveData(JSONEncoder().encode(state.syncUpsList.syncUps), .syncUps)
      }
    } catch: { _, _ in
    }
  }
}

struct AppView: View {
  @Bindable var store: StoreOf<AppFeature>

  var body: some View {
    NavigationStack(path: $store.scopes(\.path)) {
      SyncUpsListView(store: store.scopes.syncUpsList)
    } destination: { store in
      switch store.case {
      case let .detail(store):
        SyncUpDetailView(store: store)
      case let .meeting(meeting, syncUp: syncUp):
        MeetingView(meeting: meeting, syncUp: syncUp)
      case let .record(store):
        RecordMeetingView(store: store)
      }
    }
  }
}

extension URL {
  static let syncUps = Self.documentsDirectory.appending(component: "sync-ups.json")
}
