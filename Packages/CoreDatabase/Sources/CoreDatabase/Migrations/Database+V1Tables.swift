import GRDB

extension Database {
    func createV1Tables() throws {
        try createV1Accounts()
        try createV1Categories()
        try createV1Transactions()
        try createV1RecurringMovements()
        try createV1Loans()
        try createV1LoanPayments()
    }

    private func createV1Accounts() throws {
        try execute(sql: """
            CREATE TABLE accounts (
                accountId  TEXT NOT NULL PRIMARY KEY,
                name       TEXT NOT NULL,
                type       TEXT NOT NULL DEFAULT 'Bank',
                currency   TEXT NOT NULL DEFAULT 'PEN',
                updatedAt  INTEGER NOT NULL,
                createdAt  INTEGER NOT NULL,
                userId     TEXT,
                deletedAt  INTEGER,
                syncState  TEXT NOT NULL DEFAULT 'Pending'
            );
            """)
    }

    private func createV1Categories() throws {
        try execute(sql: """
            CREATE TABLE categories (
                categoryId    TEXT NOT NULL PRIMARY KEY,
                name          TEXT NOT NULL,
                icon          TEXT NOT NULL,
                color         TEXT NOT NULL,
                categoryType  TEXT NOT NULL,
                isDefault     INTEGER NOT NULL DEFAULT 0,
                updatedAt     INTEGER NOT NULL,
                createdAt     INTEGER NOT NULL,
                userId        TEXT,
                deletedAt     INTEGER,
                syncState     TEXT NOT NULL DEFAULT 'Pending'
            );
            CREATE INDEX categories_type_idx ON categories(categoryType);
            CREATE UNIQUE INDEX categories_id_type_uidx ON categories(categoryId, categoryType);
            """)
    }

    private func createV1Transactions() throws {
        try execute(sql: """
            CREATE TABLE transactions (
                transactionId  TEXT NOT NULL PRIMARY KEY,
                type           TEXT NOT NULL,
                amount         INTEGER NOT NULL,
                description    TEXT NOT NULL DEFAULT '',
                occurredAt     TEXT NOT NULL,
                categoryId     TEXT,
                accountId      TEXT NOT NULL REFERENCES accounts(accountId) ON DELETE RESTRICT,
                createdAt      INTEGER NOT NULL,
                updatedAt      INTEGER NOT NULL,
                userId         TEXT,
                deletedAt      INTEGER,
                syncState      TEXT NOT NULL DEFAULT 'Pending',
                FOREIGN KEY (categoryId, type) REFERENCES categories(categoryId, categoryType)
            );
            CREATE INDEX transactions_account_idx ON transactions(accountId);
            CREATE INDEX transactions_occurred_idx ON transactions(occurredAt);
            CREATE INDEX transactions_category_idx ON transactions(categoryId);
            """)
    }

    private func createV1RecurringMovements() throws {
        try execute(sql: """
            CREATE TABLE recurring_movements (
                id                   TEXT NOT NULL PRIMARY KEY,
                name                 TEXT NOT NULL,
                type                 TEXT NOT NULL,
                amount               INTEGER,
                description          TEXT NOT NULL DEFAULT '',
                categoryId           TEXT,
                accountId            TEXT NOT NULL REFERENCES accounts(accountId) ON DELETE RESTRICT,
                frequency            TEXT NOT NULL DEFAULT 'Monthly',
                dayOfMonth           INTEGER NOT NULL,
                isActive             INTEGER NOT NULL DEFAULT 1,
                lastConfirmedPeriod  TEXT,
                createdAt            INTEGER NOT NULL,
                updatedAt            INTEGER NOT NULL,
                userId               TEXT,
                deletedAt            INTEGER,
                syncState            TEXT NOT NULL DEFAULT 'Pending',
                FOREIGN KEY (categoryId, type) REFERENCES categories(categoryId, categoryType)
            );
            CREATE INDEX recurring_active_idx ON recurring_movements(isActive, name);
            """)
    }

    private func createV1Loans() throws {
        try execute(sql: """
            CREATE TABLE loans (
                loanId       TEXT NOT NULL PRIMARY KEY,
                personName   TEXT NOT NULL,
                personKey    TEXT NOT NULL,
                principal    INTEGER NOT NULL,
                interestBps  INTEGER NOT NULL DEFAULT 0,
                totalDue     INTEGER NOT NULL,
                note         TEXT NOT NULL DEFAULT '',
                lentAt       TEXT NOT NULL,
                createdAt    INTEGER NOT NULL,
                updatedAt    INTEGER NOT NULL,
                userId       TEXT,
                deletedAt    INTEGER,
                syncState    TEXT NOT NULL DEFAULT 'Pending'
            );
            CREATE INDEX loans_person_idx ON loans(personKey);
            """)
    }

    private func createV1LoanPayments() throws {
        try execute(sql: """
            CREATE TABLE loan_payments (
                paymentId  TEXT NOT NULL PRIMARY KEY,
                loanId     TEXT NOT NULL REFERENCES loans(loanId) ON DELETE RESTRICT,
                amount     INTEGER NOT NULL,
                method     TEXT NOT NULL,
                paidAt     TEXT NOT NULL,
                note       TEXT NOT NULL DEFAULT '',
                createdAt  INTEGER NOT NULL,
                updatedAt  INTEGER NOT NULL,
                userId     TEXT,
                deletedAt  INTEGER,
                syncState  TEXT NOT NULL DEFAULT 'Pending'
            );
            CREATE INDEX loan_payments_loan_idx ON loan_payments(loanId);
            """)
    }
}
