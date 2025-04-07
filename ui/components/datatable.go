package components

import "html/template"

type DataTable struct {
	Name       string
	FlexGrow   int
	Header     []string
	Rows       []*DataTableRow
	OnRowClick template.JS
}

type DataTableRow struct {
	RowId int
	Cells []*DataTableCell
}

type DataTableCell struct {
	Value         any
	DisplayString string
	Strong        bool
	CustomStyle   string
}

func NewDataTable(name string, flexGrow int, onRowClick string, headers ...string) *DataTable {
	return &DataTable{
		Name:     name,
		FlexGrow: flexGrow,
		Header:   headers,
		Rows:     make([]*DataTableRow, 0),
		OnRowClick: func() template.JS {
			if onRowClick != "" {
				return template.JS(onRowClick)
			}
			return template.JS("")
		}(),
	}
}

func (d *DataTable) AddRow(rowId int, cells ...*DataTableCell) *DataTable {
	d.Rows = append(d.Rows, &DataTableRow{RowId: rowId, Cells: cells})
	return d
}

func NewDataTableCell(value any, displayString string) *DataTableCell {
	return &DataTableCell{
		Value:         value,
		DisplayString: displayString,
	}
}
