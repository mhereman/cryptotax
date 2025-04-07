package handlers

import (
	"html/template"
	"net/http"

	"github.com/mhereman/cryptotax/backend/cryptodb"
	"github.com/mhereman/cryptotax/ui/components"
)

type transactionsOverviewData struct {
	PageSize         int
	Page             int
	Year             int
	NumTransactions  int
	NumPages         int
	TransactionTable *components.DataTable
}

func TransactionsOverview(templates *template.Template) Handler {
	return func(w http.ResponseWriter, r *http.Request) {
		// Read arguments
		year := getIntArgument(r, "year", getCurrentYear())
		page := getPageArgument(r, 1)
		pageSize := getPageSizeArgument(r)

		fiatAsset, fiatAssetMap, cryptoAssetMap, err := getAssetInfo()
		if err != nil {
			panic(err)
		}

		num, err := cryptodb.CountTransactions(year)
		if err != nil {
			panic(err)
		}
		txList, err := cryptodb.LoadTransactions(year, page, pageSize)
		if err != nil {
			panic(err)
		}

		transactionsOverviewData := &transactionsOverviewData{
			Year:            year,
			PageSize:        pageSize,
			NumTransactions: num,
			NumPages:        (num + pageSize - 1) / pageSize,
		}
		transactionsOverviewData.Page = max(transactionsOverviewData.NumPages, 1)

		dt := components.NewDataTable("Transactions", 1, "alert", "Date", "Type", "Amount Sold", "Amount Bought", "Fee", "Profit / Loss", "Taxable Profit / Loss", "Description")
		for _, tx := range txList {
			dt.AddRow(
				tx.Id,
				getTransactionsOverviewDataTableCell(
					&tx, "Date", fiatAsset, fiatAssetMap, cryptoAssetMap),
				getTransactionsOverviewDataTableCell(
					&tx, "Type", fiatAsset, fiatAssetMap, cryptoAssetMap),
				getTransactionsOverviewDataTableCell(
					&tx, "Amount Sold", fiatAsset, fiatAssetMap, cryptoAssetMap),
				getTransactionsOverviewDataTableCell(
					&tx, "Amount Bought", fiatAsset, fiatAssetMap, cryptoAssetMap),
				getTransactionsOverviewDataTableCell(
					&tx, "Fee", fiatAsset, fiatAssetMap, cryptoAssetMap),
				getTransactionsOverviewDataTableCell(
					&tx, "Profit / Loss", fiatAsset, fiatAssetMap, cryptoAssetMap),
				getTransactionsOverviewDataTableCell(
					&tx, "Taxable Profit / Loss", fiatAsset, fiatAssetMap, cryptoAssetMap),
				getTransactionsOverviewDataTableCell(
					&tx, "Description", fiatAsset, fiatAssetMap, cryptoAssetMap),
			)
		}
		transactionsOverviewData.TransactionTable = dt

		if err := templates.ExecuteTemplate(
			w, "transactions_overview.html",
			transactionsOverviewData,
		); err != nil {
			panic(err)
		}
	}
}

func getTransactionsOverviewDataTableCell(
	t *cryptodb.Transaction,
	columnName string,
	fiatAsset *cryptodb.FiatAsset,
	fiatAssetMap map[string]*cryptodb.FiatAsset,
	cryptoAssetMap map[string]*cryptodb.CryptoAsset,
) (cell *components.DataTableCell) {
	switch columnName {
	case "Date":
		cell = components.NewDataTableCell(t.DateTime, t.DateTime.Format("02-01-2006 15:04:05"))
		cell.Strong = true
	case "Type":
		cell = components.NewDataTableCell(t.TransactionType, t.TransactionType)
	case "Amount Sold":
		if d, a, f := t.GetAmountSold(); d != nil {
			cell = components.NewDataTableCell(
				*d, formatAsset(d, a, f, fiatAsset, fiatAssetMap, cryptoAssetMap))
		} else {
			cell = components.NewDataTableCell(nil, "")
		}
	case "Amount Bought":
		if d, a, f := t.GetAmountBought(); d != nil {
			cell = components.NewDataTableCell(
				*d, formatAsset(d, a, f, fiatAsset, fiatAssetMap, cryptoAssetMap))
		} else {
			cell = components.NewDataTableCell(nil, "")
		}
	case "Fee":
		if d, a, f := t.GetFee(); d != nil {
			cell = components.NewDataTableCell(
				*d, formatAsset(d, a, f, fiatAsset, fiatAssetMap, cryptoAssetMap))
		} else {
			cell = components.NewDataTableCell(nil, "")
		}
	case "Profit / Loss":
		if d := t.GetProfitLoss(); d != nil {
			cell = components.NewDataTableCell(*d, fiatAsset.Format(*d, cryptodb.FiatFormatZeroDash, cryptodb.FiatFormatNegativeParenteses))
			cell.Strong = true
			if !d.IsZero() {
				if d.IsNegative() {
					cell.CustomStyle = "color: red"
				} else {
					cell.CustomStyle = "color: green"
				}
			}
		} else {
			cell = components.NewDataTableCell(nil, "")
		}
	case "Taxable Profit / Loss":
		if d := t.GetTaxableProfitLoss(); d != nil {
			cell = components.NewDataTableCell(*d, fiatAsset.Format(*d, cryptodb.FiatFormatZeroDash, cryptodb.FiatFormatNegativeParenteses))
			cell.Strong = true
			if !d.IsZero() {
				if d.IsNegative() {
					cell.CustomStyle = "color: red"
				} else {
					cell.CustomStyle = "color: green"
				}
			}
		} else {
			cell = components.NewDataTableCell(nil, "")
		}
	case "Description":
		cell = components.NewDataTableCell(t.Description.String, t.Description.String)
	default:
		cell = components.NewDataTableCell(nil, "")
	}
	return cell
}
