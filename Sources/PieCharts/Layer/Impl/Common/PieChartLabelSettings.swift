//
//  PieChartLabelSettings.swift
//  PieCharts
//
//  Created by Ivan Schuetz on 30/12/2016.
//  Copyright © 2016 Ivan Schuetz. All rights reserved.
//

import UIKit

public class PieChartLabelSettings {
    public var textColor: UIColor = UIColor.black
    public var bgColor: UIColor = UIColor.clear
    public var font: UIFont = UIFont.boldSystemFont(ofSize: 20)

    public var textGenerator: (PieSlice, _ title: Bool) -> String = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.currencySymbol = ""
        return ($1 ? $0.data.model.title : formatter.string(from: NSNumber(value: $0.data.model.value))) ?? "\($0.data.model.value)"
    }

    // Optional custom label - when this is set presentations settings (textColor, etc.) are ignored
    public var labelGenerator: ((PieSlice) -> UILabel)?
}
