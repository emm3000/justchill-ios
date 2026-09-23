import GRDB

extension Database {
    func seedV1Defaults() throws {
        try seedV1Categories()
        try seedV1CashAccount()
    }

    private func seedV1Categories() throws {
        try execute(sql: """
            INSERT INTO categories (categoryId, name, icon, color, categoryType, isDefault, updatedAt, createdAt) VALUES
            ('22fc771d-702d-4aa0-8d03-558c42cf1b87', 'Supermercado', 'groceries', 'green', 'Spend', 1, 1790035200000, 1790035200000),
            ('6e692f0e-d4ee-4e73-af87-7f5e3ad127d5', 'Restaurantes', 'food', 'orange', 'Spend', 1, 1790035200000, 1790035200000),
            ('a4d8c0db-a271-4581-9d0e-7fbafa877f98', 'Comida rápida', 'fast_food', 'red', 'Spend', 1, 1790035200000, 1790035200000),
            ('e74e45ac-b75d-47da-b98a-4e2c57e20eea', 'Café', 'coffee', 'brown', 'Spend', 1, 1790035200000, 1790035200000),
            ('e2ad88c1-4e3f-429b-8981-65a613e0f8dc', 'Bar', 'bar', 'purple', 'Spend', 1, 1790035200000, 1790035200000),
            ('f089fa4f-166d-4583-8be2-b1c28be821cf', 'Transporte', 'car', 'blue', 'Spend', 1, 1790035200000, 1790035200000),
            ('a9f654c0-0267-4f11-a1e0-7874dc3586a7', 'Taxi', 'taxi', 'yellow', 'Spend', 1, 1790035200000, 1790035200000),
            ('81d7e2df-9457-449e-9ce9-edf3b8056e61', 'Transporte público', 'bus', 'teal', 'Spend', 1, 1790035200000, 1790035200000),
            ('e893f567-f2b3-477f-b878-576ef3aec90f', 'Gasolina', 'fuel', 'orange', 'Spend', 1, 1790035200000, 1790035200000),
            ('fc644126-5b7a-46f7-9a77-10620b51aeb7', 'Estacionamiento', 'parking', 'gray', 'Spend', 1, 1790035200000, 1790035200000),
            ('16e9595f-47b7-49a7-8402-13f895af065e', 'Alquiler', 'rent', 'purple', 'Spend', 1, 1790035200000, 1790035200000),
            ('c11e888c-b9d0-41d9-b121-2a83cadbad9e', 'Servicios básicos', 'utilities', 'yellow', 'Spend', 1, 1790035200000, 1790035200000),
            ('b7503b5e-003f-4cb0-8731-5047346b0f3a', 'Internet', 'internet', 'blue', 'Spend', 1, 1790035200000, 1790035200000),
            ('0e1444ee-a425-489d-9418-69ab24bbd37f', 'Reparaciones del hogar', 'repairs', 'brown', 'Spend', 1, 1790035200000, 1790035200000),
            ('c3f9161b-78f1-45fb-8660-94e506923045', 'Limpieza', 'cleaning', 'teal', 'Spend', 1, 1790035200000, 1790035200000),
            ('13c83762-f5e7-4801-baf3-6cff2d967eb3', 'Sueldo', 'salary', 'green', 'Income', 1, 1790035200000, 1790035200000),
            ('3e6df420-ba5f-4170-827c-784062e07040', 'Freelance', 'freelance', 'blue', 'Income', 1, 1790035200000, 1790035200000),
            ('44c4ec23-ac21-4b76-b0f4-250589b11841', 'Inversiones', 'investment', 'purple', 'Income', 1, 1790035200000, 1790035200000),
            ('830f4070-f2f8-47f8-af73-360b96d6cd3d', 'Ahorros', 'savings', 'teal', 'Income', 1, 1790035200000, 1790035200000),
            ('149e77e6-8a36-460f-8ef6-6b4021fcd032', 'Ventas', 'shopping', 'blue', 'Income', 1, 1790035200000, 1790035200000),
            ('3f4a84e2-cd30-4cc3-85d3-76717f7de1eb', 'Propinas', 'tips', 'yellow', 'Income', 1, 1790035200000, 1790035200000),
            ('a89f117e-dbcc-4977-a65a-160802acd9e6', 'Otros', 'wallet', 'gray', 'Income', 1, 1790035200000, 1790035200000),
            ('442e13d9-2b2e-4a40-b8df-3d55b89253d8', 'Tarjeta de crédito', 'credit_card', 'red', 'Spend', 1, 1790035200000, 1790035200000);
            """)
    }

    private func seedV1CashAccount() throws {
        try execute(sql: """
            INSERT INTO accounts (accountId, name, type, currency, updatedAt, createdAt) VALUES
            ('756f551d-ad41-4c53-a6e8-6704a1473caa', 'Efectivo', 'Cash', 'PEN', 1790035200000, 1790035200000);
            """)
    }
}
