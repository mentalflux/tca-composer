import ComposableArchitecture
import SwiftUI
import TCAComposer

@ComposeReducer(.bindable)
@Composer
struct VoiceMemo {
  struct State: Equatable, Identifiable {
    var date: Date
    var duration: TimeInterval
    var mode = Mode.notPlaying
    var title = ""
    var url: URL

    var id: URL { self.url }

    @CasePathable
    @dynamicMemberLookup
    enum Mode: Equatable {
      case notPlaying
      case playing(progress: Double)
    }
  }

  enum Actions {
    @ComposeActionCase
    enum Delegate {
      case playbackStarted
      case playbackFailed
    }

    enum Effect {
      case audioPlayerClient(Result<Bool, Error>)
      case timerUpdated(TimeInterval)
    }

    enum View {
      case playButtonTapped
    }
  }

  @Dependency(\.audioPlayer) var audioPlayer
  @Dependency(\.continuousClock) var clock
  private enum CancelID { case play }

  @ComposeBodyActionCase
  func effect(state: inout State, action: Actions.Effect) -> EffectOf<Self> {
    switch action {
    case .audioPlayerClient(.failure):
      state.mode = .notPlaying
      return .merge(
        .cancel(id: CancelID.play),
        .send(.delegate(.playbackFailed))
      )

    case .audioPlayerClient:
      state.mode = .notPlaying
      return .cancel(id: CancelID.play)

    case let .timerUpdated(time):
      switch state.mode {
      case .notPlaying:
        break
      case .playing:
        state.mode = .playing(progress: time / state.duration)
      }
      return .none
    }
  }

  @ComposeBodyActionCase
  func view(state: inout State, action: Actions.View) -> EffectOf<Self> {
    switch action {
    case .playButtonTapped:
      switch state.mode {
      case .notPlaying:
        state.mode = .playing(progress: 0)

        return .run { [url = state.url] send in
          await send(.delegate(.playbackStarted))

          async let playAudio: Void = send(
            .effect(.audioPlayerClient(Result { try await self.audioPlayer.play(url: url) }))
          )

          var start: TimeInterval = 0
          for await _ in self.clock.timer(interval: .milliseconds(500)) {
            start += 0.5
            await send(.effect(.timerUpdated(start)))
          }

          await playAudio
        }
        .cancellable(id: CancelID.play, cancelInFlight: true)

      case .playing:
        state.mode = .notPlaying
        return .cancel(id: CancelID.play)
      }
    }
  }
}

@ViewAction(for: VoiceMemo.self)
struct VoiceMemoView: View {
  @Bindable var store: StoreOf<VoiceMemo>

  var body: some View {
    let currentTime =
      store.mode.playing.map { $0 * store.duration } ?? store.duration
    HStack {
      TextField(
        "Untitled, \(store.date.formatted(date: .numeric, time: .shortened))",
        text: $store.title
      )

      Spacer()

      dateComponentsFormatter.string(from: currentTime).map {
        Text($0)
          .font(.footnote.monospacedDigit())
          .foregroundColor(Color(.systemGray))
      }

      Button {
        send(.playButtonTapped)
      } label: {
        Image(systemName: store.mode.is(\.playing) ? "stop.circle" : "play.circle")
          .font(.system(size: 22))
      }
    }
    .buttonStyle(.borderless)
    .frame(maxHeight: .infinity, alignment: .center)
    .padding(.horizontal)
    .listRowBackground(store.mode.is(\.playing) ? Color(.systemGray6) : .clear)
    .listRowInsets(EdgeInsets())
    .background(
      Color(.systemGray5)
        .frame(maxWidth: store.mode.is(\.playing) ? .infinity : 0)
        .animation(
          store.mode.is(\.playing) ? .linear(duration: store.duration) : nil,
          value: store.mode.is(\.playing)
        ),
      alignment: .leading
    )
  }
}
