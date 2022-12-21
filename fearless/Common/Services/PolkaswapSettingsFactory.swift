//
//  PolkaswapSettingsFactory.swift
//  fearless
//
//  Created by Soramitsu on 19.12.2022.
//  Copyright © 2022 Soramitsu. All rights reserved.
//

import Foundation
import RobinHood
import FearlessUtils

final class PolkaswapSettingsFactory {
    static func createService() -> PolkaswapSettingsSyncServiceProtocol {
        let repositoryFacade = SubstrateDataStorageFacade.shared

        let mapper = PolkaswapSettingMapper()

        let repository: CoreDataRepository<PolkaswapRemoteSettings, CDPolkaswapRemoteSettings>
            = repositoryFacade.createRepository(
                filter: nil,
                sortDescriptors: [],
                mapper: AnyCoreDataMapper(mapper)
            )

        let service = PolkaswapSettingsSyncService(
            settingsUrl: ApplicationConfig.shared.polkaswapSettingsURL,
            dataFetchFactory: DataOperationFactory(),
            repository: AnyDataProviderRepository(repository),
            operationQueue: OperationManagerFacade.sharedDefaultQueue
        )

        return service
    }
}
