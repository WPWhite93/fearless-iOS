import Foundation
import SoraFoundation
import SoraKeystore
import IrohaCrypto

final class WebSocketService: WebSocketServiceProtocol {
    static let shared: WebSocketService = {
        let connectionItem = SettingsManager.shared.selectedConnection
        let address = SettingsManager.shared.selectedAccount?.address

        let settings = WebSocketServiceSettings(
            url: connectionItem.url,
            addressType: connectionItem.type,
            address: address
        )
        let storageFacade = SubstrateDataStorageFacade.shared
        let subscriptionFactory = WebSocketSubscriptionFactory(
            storageFacade: storageFacade,
            runtimeService: RuntimeRegistryFacade.sharedService,
            operationManager: OperationManagerFacade.sharedManager
        )
        return WebSocketService(
            settings: settings,
            chainRegistry: ChainRegistryFacade.sharedRegistry,
            subscriptionsFactory: subscriptionFactory,
            applicationHandler: ApplicationHandler()
        )
    }()

    enum State {
        case throttled
        case active
        case inactive
    }

    var connection: JSONRPCEngine? { engine }

    let applicationHandler: ApplicationHandlerProtocol
    let chainRegistry: ChainRegistryProtocol
    let subscriptionsFactory: WebSocketSubscriptionFactoryProtocol

    private(set) var settings: WebSocketServiceSettings
    private(set) var engine: WebSocketEngine?
    private(set) var subscriptions: [WebSocketSubscribing]?

    private(set) var isThrottled: Bool = true
    private(set) var isActive: Bool = true

    var networkStatusPresenter: NetworkAvailabilityLayerInteractorOutputProtocol?

    init(
        settings: WebSocketServiceSettings,
        chainRegistry: ChainRegistryProtocol,
        subscriptionsFactory: WebSocketSubscriptionFactoryProtocol,
        applicationHandler: ApplicationHandlerProtocol
    ) {
        self.settings = settings
        self.applicationHandler = applicationHandler
        self.chainRegistry = chainRegistry
        self.subscriptionsFactory = subscriptionsFactory
    }

    func setup() {
        guard isThrottled else {
            return
        }

        isThrottled = false

        applicationHandler.delegate = self

        setupConnection()
    }

    func throttle() {
        guard !isThrottled else {
            return
        }

        isThrottled = true

        clearConnection()
    }

    func update(settings: WebSocketServiceSettings) {
        guard self.settings != settings else {
            return
        }

        self.settings = settings

        if !isThrottled {
            clearConnection()
            setupConnection()
        }
    }

    private func clearConnection() {
        engine?.delegate = nil
        engine?.disconnectIfNeeded()
        engine = nil

        subscriptions = nil
    }

    private func setupConnection() {
        if
            let address = settings.address,
            let type = settings.addressType,
            let engine = chainRegistry.getConnection(for: type.chain.genesisHash) as? WebSocketEngine {
            engine.delegate = self
            self.engine = engine

            subscriptions = try? subscriptionsFactory.createSubscriptions(
                address: address,
                type: type,
                engine: engine
            )
        } else {
            engine?.delegate = nil
            engine = nil
            subscriptions = nil
        }
    }
}

extension WebSocketService: ApplicationHandlerDelegate {
    func didReceiveDidBecomeActive(notification _: Notification) {
        if !isThrottled, !isActive {
            isActive = true

            engine?.connectIfNeeded()
        }
    }

    func didReceiveDidEnterBackground(notification _: Notification) {
        if !isThrottled, isActive {
            isActive = false

            engine?.disconnectIfNeeded()
        }
    }
}

extension WebSocketService: WebSocketEngineDelegate {
    func webSocketDidChangeState(
        from _: ConnectionState,
        to newState: ConnectionState
    ) {
        switch newState {
        case let .connecting(attempt):
            if attempt > 1 {
                scheduleNetworkUnreachable()
            }
        case .connected:
            scheduleNetworkReachable()
        default:
            break
        }
    }

    private func scheduleNetworkReachable() {
        DispatchQueue.main.async {
            self.networkStatusPresenter?.didDecideReachableStatusPresentation()
        }
    }

    private func scheduleNetworkUnreachable() {
        DispatchQueue.main.async {
            self.networkStatusPresenter?.didDecideUnreachableStatusPresentation()
        }
    }
}
