package assettypes

import (
	"github.com/goledgerdev/cc-tools/assets"
)

var Payment = assets.AssetType{
	Tag:         "payment",
	Label:       "Payment",
	Description: "Payment",

	Props: []assets.AssetProp{
		{
			// Primary key
			IsKey:    true,
			Tag:      "orderId",
			Label:    "Order ID",
			DataType: "number",
		},
		{
			Tag:      "paymentTypeId",
			Label:    "Payment Type Id",
			DataType: "number",
		},
		{
			Tag:      "tableId",
			Label:    "Table Id",
			DataType: "number",
		},
		{
			Tag:      "orderNumber",
			Label:    "Order Number",
			DataType: "number",
		},
		{
			Tag:      "orderDate",
			Label:    "Order Date",
			DataType: "string",
		},
		{
			Tag:      "finalTotal",
			Label:    "Final Total",
			DataType: "number",
		},
	},
}
