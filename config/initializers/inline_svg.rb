# Configure inline_svg for Avo compatibility with Rails API mode
InlineSvg.configure do |config|
  config.asset_finder = InlineSvg::StaticAssetFinder
end
