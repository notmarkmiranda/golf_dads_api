# Known Issues

## ActiveSupport::Configurable Deprecation Warning

**Issue:** Deprecation warning appears when running tests:
```
DEPRECATION WARNING: ActiveSupport::Configurable is deprecated without replacement,
and will be removed in Rails 8.2.
```

**Source:** This warning comes from the Avo admin gem or one of its dependencies using deprecated Rails 8.1 APIs.

**Impact:** No functional impact - this is just a warning. All tests pass successfully.

**Resolution:** This will be fixed when Avo releases an updated version compatible with Rails 8.2. Monitor https://github.com/avo-hq/avo for updates.

**Status:** Known issue, waiting for upstream fix.

---

## Rack :unprocessable_entity Deprecation

**Issue:** Warning about deprecated HTTP status code:
```
Status code :unprocessable_entity is deprecated and will be removed in a future version of Rack.
Please use :unprocessable_content instead.
```

**Source:** RSpec Rails matchers using deprecated status code symbols.

**Impact:** No functional impact - HTTP 422 responses work correctly.

**Resolution:** Will be fixed in future RSpec Rails update.

**Status:** Known issue, waiting for upstream fix.
