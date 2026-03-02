module QrCodeHelper
  def qr_code_svg(url, size: 150)
    qrcode = RQRCode::QRCode.new(url)
    qrcode.as_svg(
      module_size: 3,
      standalone: true,
      use_path: true,
      viewbox: true,
      svg_attributes: {
        width: size,
        height: size,
        class: "qr-code"
      }
    ).html_safe
  end
end
