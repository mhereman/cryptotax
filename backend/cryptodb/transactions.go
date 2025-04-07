package cryptodb

import (
	"database/sql"
	"time"

	"github.com/shopspring/decimal"
)

type Transaction struct {
	Id                      int
	DateTime                time.Time
	TransactionType         string
	IsFiatTransaction       bool
	Description             sql.NullString
	Reference               sql.NullString
	Link                    sql.NullString
	TransactionPnL          decimal.Decimal
	TaxablePnL              decimal.Decimal
	ValuationAsset          sql.NullString
	ValuationValue          decimal.NullDecimal
	ValuationFiatQuoteValue decimal.NullDecimal
	ValuationIsFiat         sql.NullBool
	BuyAsset                sql.NullString
	BuyValue                decimal.NullDecimal
	BuyFiatQuoteValue       decimal.NullDecimal
	BuyIsFiat               sql.NullBool
	SellAsset               sql.NullString
	SellValue               decimal.NullDecimal
	SellFiatQuoteValue      decimal.NullDecimal
	SellIsFiat              sql.NullBool
	FeeAsset                sql.NullString
	FeeValue                decimal.NullDecimal
	FeeFiatQuoteValue       decimal.NullDecimal
	FeeIsFiat               sql.NullBool
}

func (t Transaction) GetAmountSold() (*decimal.Decimal, string, bool) {
	switch t.TransactionType {
	case "Initialisation":
		d := t.ValuationValue.Decimal.Mul(t.ValuationFiatQuoteValue.Decimal)
		return &d, "", true
	case "Trade":
		return &t.SellValue.Decimal, t.SellAsset.String, t.SellIsFiat.Bool
	default:
		return nil, "", false
	}
}

func (t Transaction) GetAmountBought() (*decimal.Decimal, string, bool) {
	switch t.TransactionType {
	case "Initialisation":
		return &t.ValuationValue.Decimal, t.ValuationAsset.String, false
	case "Trade":
		return &t.BuyValue.Decimal, t.BuyAsset.String, t.BuyIsFiat.Bool
	default:
		return nil, "", false
	}
}

func (t Transaction) GetFee() (*decimal.Decimal, string, bool) {
	if !t.FeeValue.Valid {
		return nil, "", false
	}

	switch t.TransactionType {
	case "Trade", "TransactionFee":
		return &t.FeeValue.Decimal, t.FeeAsset.String, t.FeeIsFiat.Bool
	default:
		return nil, "", false
	}
}

func (t Transaction) GetProfitLoss() *decimal.Decimal {
	return &t.TransactionPnL
}

func (t Transaction) GetTaxableProfitLoss() *decimal.Decimal {
	return &t.TaxablePnL
}

func CountTransactions(year int) (int, error) {
	const query = `SELECT COUNT(*) FROM crypto.ViewTransactionList WHERE date_part('year', DateTime) = $1;`
	var count int
	err := db.QueryRow(query, year).Scan(&count)
	return count, err
}

func LoadTransactions(year int, page int, pagesize int) ([]Transaction, error) {
	// Get all transactions in the given year
	const query = `SELECT
		Id, DateTime, Type, IsFiatEvent,
		Description, Reference, Link,
		TransactionPnL, TaxablePnL,
		ValuationAsset, ValuationValue, ValuationFiatQuoteValue, ValuationIsFiat,
		BuyAsset, BuyValue, BuyFiatQuoteValue, BuyIsFiat,
		SellAsset, SellValue, SellFiatQuoteValue, SellIsFiat,
		FeeAsset, FeeValue, FeeFiatQuoteValue, FeeIsFiat
	FROM crypto.ViewTransactionList
	WHERE date_part('year', DateTime) = $1
	ORDER BY DateTime ASC, Id ASC
	LIMIT $2 OFFSET $3;`
	rows, err := db.Query(query, year, pagesize, (page-1)*pagesize)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	// Load all transactions
	transactions := make([]Transaction, 0)
	for rows.Next() {
		var t Transaction
		err := rows.Scan(
			&t.Id, &t.DateTime, &t.TransactionType, &t.IsFiatTransaction,
			&t.Description, &t.Reference, &t.Link,
			&t.TransactionPnL, &t.TaxablePnL,
			&t.ValuationAsset, &t.ValuationValue, &t.ValuationFiatQuoteValue, &t.ValuationIsFiat,
			&t.BuyAsset, &t.BuyValue, &t.BuyFiatQuoteValue, &t.BuyIsFiat,
			&t.SellAsset, &t.SellValue, &t.SellFiatQuoteValue, &t.SellIsFiat,
			&t.FeeAsset, &t.FeeValue, &t.FeeFiatQuoteValue, &t.FeeIsFiat,
		)
		if err != nil {
			return nil, err
		}
		transactions = append(transactions, t)
	}
	return transactions, nil
}
