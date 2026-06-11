import Capacitor
import FlyBuy
import FlyBuyPickup

@objc(FlybuyPickupPlugin)
public class FlybuyPickupPlugin: CAPPlugin {

    // MARK: - Order Observers

    private var orderObservers: [NSObjectProtocol] = []

    public override func load() {
        let updatedObserver = NotificationCenter.default.addObserver(
            forName: .ordersUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            let orders = (try? FlyBuy.Core.getInstance(forAppAuthId: nil))?.orders.all ?? []
            self.notifyListeners("ordersUpdated", data: [
                "orders": orders.map { self.serializeOrder($0) }
            ])
        }

        let singleObserver = NotificationCenter.default.addObserver(
            forName: .orderUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            if let order = notification.object as? Order {
                self.notifyListeners("orderUpdated", data: [
                    "order": self.serializeOrder(order)
                ])
            }
        }

        let errorObserver = NotificationCenter.default.addObserver(
            forName: .ordersError,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            if let error = notification.object as? Error {
                self.notifyListeners("ordersError", data: [
                    "error": error.localizedDescription
                ])
            }
        }

        orderObservers = [updatedObserver, singleObserver, errorObserver]
    }

    deinit {
        orderObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - Serializers

    private func serializeOrder(_ order: Order) -> [String: Any] {
        var dict: [String: Any] = [
            "id": order.id,
            "state": order.state,
            "customerState": order.customerState,
            "isOpen": order.isOpen(),
            "siteID": order.siteID,
        ]
        if let partnerIdentifier = order.partnerIdentifier { dict["partnerIdentifier"] = partnerIdentifier }
        if let redeemedAt = order.redeemedAt { dict["redeemedAt"] = ISO8601DateFormatter().string(from: redeemedAt) }
        if let rating = order.customerRating { dict["customerRatingValue"] = rating }
        if let spotEnabled = order.spotIdentifierEntryEnabled { dict["spotIdentifierEntryEnabled"] = spotEnabled }
        if let pickupType = order.pickupType { dict["pickupType"] = pickupType }
        if let customerName = order.customerName { dict["customerName"] = customerName }
        if let customerCarType = order.customerCarType { dict["customerCarType"] = customerCarType }
        if let customerCarColor = order.customerCarColor { dict["customerCarColor"] = customerCarColor }
        if let customerLicensePlate = order.customerLicensePlate { dict["customerCarPlate"] = customerLicensePlate }
        if let eta = order.etaAt { dict["etaAtStop"] = ISO8601DateFormatter().string(from: eta) }
        if let window = order.pickupWindow {
            var windowDict: [String: Any] = ["start": ISO8601DateFormatter().string(from: window.start)]
            windowDict["end"] = ISO8601DateFormatter().string(from: window.end)
            dict["pickupWindow"] = windowDict
        }
        return dict
    }
}