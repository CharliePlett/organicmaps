import Foundation
extension UISearchBar {
  @objc override func applyTheme() {
    if styleName.isEmpty {
      styleName = "SearchBar"
    }
    for style in StyleManager.shared.getStyle(styleName)
      where !style.isEmpty && !style.hasExclusion(view: self) {
      UISearchBarRenderer.render(self, style: style)
    }
  }

  @objc override func sw_didMoveToWindow() {
    guard MapsAppDelegate.theApp().window === window else {
      sw_didMoveToWindow();
      return
    }
    applyTheme()
    isStyleApplied = true
    sw_didMoveToWindow();
  }
}

class UISearchBarRenderer: UIViewRenderer {
  class func render(_ control: UISearchBar, style: Style) {
    super.render(control, style: style)
    if #available(iOS 13, *) {
      var searchTextField = control.searchTextField
      // Default search bar implementation adds the grey transparent image for background. This code removes it and updates the corner radius. This is not working on iPad designed for mac.
      if #available(iOS 14.0, *), ProcessInfo.processInfo.isiOSAppOnMac {
      } else {
        control.setSearchFieldBackgroundImage(UIImage(), for: .normal)
      }
      searchTextField.layer.setCorner(radius: 8)
      searchTextField.layer.masksToBounds = true
      // Placeholder color
      if let placeholder = searchTextField.placeholder {
        searchTextField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [.foregroundColor: UIColor.gray])
      }
      if let backgroundColor = style.backgroundColor {
        searchTextField.backgroundColor = backgroundColor
      }
      if let font = style.font {
        searchTextField.font = font
      }
      if let fontColor = style.fontColor {
        searchTextField.textColor = fontColor
      }
      if let tintColor = style.tintColor {
        searchTextField.leftView?.tintColor = tintColor
        // Placeholder indicator color
        searchTextField.tintColor = tintColor
        // Clear button image
        let clearButtonImage = UIImage(named: "ic_clear")?.withRenderingMode(.alwaysTemplate).withTintColor(tintColor)
        control.setImage(clearButtonImage, for: .clear, state: .normal)
      }
    } else {
      // Default search bar implementation for iOS12 adds the dark grey transparent image for background. This code removes it and replace with the custom image accordingly to the documentation - see 'setSearchFieldBackgroundImage'.
      if let backgroundColor = style.backgroundColor {
        let image = searchBarBackgroundImage(color: backgroundColor)
        control.setSearchFieldBackgroundImage(image, for: .normal)
        control.searchTextPositionAdjustment = UIOffset(horizontal: 6.0, vertical: 0.0)
      }
    }
    if let barTintColor = style.barTintColor {
      let position = control.delegate?.position?(for: control) ?? control.barPosition
      control.setBackgroundImage(barTintColor.getImage(), for: position, barMetrics: .defaultPrompt)
      control.setBackgroundImage(barTintColor.getImage(), for: position, barMetrics: .default)
      control.backgroundColor = barTintColor
    }
    if let fontColorDetailed = style.fontColorDetailed {
      // Cancel button color
      control.tintColor = fontColorDetailed
    }
  }

  //fix for iOS 12 and below
  class func setAppearance() {
    for style in StyleManager.shared.getStyle("SearchBar") {
      if let backgroundColor = style.backgroundColor {
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).backgroundColor = backgroundColor
      }
      if let font = style.font {
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).font = font
      }
      if let fontColor = style.fontColor {
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [.foregroundColor: fontColor]
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = fontColor
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).leftView?.tintColor = fontColor
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = fontColor
      }
    }
  }

  // Draws the background image for the UITextField using the default system's text field height.
  // This approach is used only for iOS 12.
  private class func searchBarBackgroundImage(color: UIColor) -> UIImage? {
    let size = CGSize(width: 36, height: 36)
    UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    let rect = CGRect(origin: .zero, size: size)
    let cornerRadius = CGFloat(8)
    let path = UIBezierPath(roundedRect: rect, byRoundingCorners: [.topLeft, .topRight, .bottomLeft, .bottomRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
    context.addPath(path.cgPath)
    context.setFillColor(color.cgColor)
    context.fillPath()
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
  }
}
