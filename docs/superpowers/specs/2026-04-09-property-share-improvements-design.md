# Property Share Improvements

## Summary

Three changes to the existing property sharing feature in the admin panel:

1. Rename `PropertyMailer#share_email` to `#share_property`
2. Add an email preview to the share page
3. Configure Brevo SMTP for actual email delivery

## 1. Rename share_email to share_property

Rename across all files:

- `PropertyMailer#share_email` → `#share_property`
- `app/views/property_mailer/share_email.html.erb` → `share_property.html.erb`
- `Admin::PropertySharesController#create` call site
- All related tests

## 2. Email preview on the share page

### Flow

The existing share page (`admin/property_shares/new.html.erb`) gains an email preview above the contact selection list. The full flow:

1. Admin clicks "Share" on a property
2. Page shows the rendered email preview at the top, contact checkboxes below
3. Admin selects contacts and clicks "Send"

### Implementation

- In `PropertySharesController#new`, render the mailer template into an instance variable:
  ```ruby
  @email_preview = PropertyMailer.share_property(@property, nil).body.decoded
  ```
- Display the preview in an `<iframe srcdoc="...">` element, which isolates the email's inline styles from the admin layout CSS.
- The mailer template handles a `nil` contact by rendering "Bonjour," with no name. When a real contact is passed, it renders "Bonjour [first_name] [last_name],".

### View structure

```
+----------------------------------+
|  Email Preview (iframe)          |
|  [rendered email HTML]           |
+----------------------------------+
|  Select contacts                 |
|  [ ] Alice Dupont (alice@...)    |
|  [ ] Bob Martin (bob@...)        |
|  [Send]                          |
+----------------------------------+
```

## 3. Brevo SMTP configuration

Standard Action Mailer SMTP in `config/environments/production.rb`:

- Host: `smtp-relay.brevo.com`
- Port: 587
- Authentication: `:plain`
- STARTTLS enabled
- Credentials from Rails encrypted credentials: `credentials.dig(:smtp, :user_name)` and `credentials.dig(:smtp, :password)`

No additional gems required.

## 4. Testing (TDD)

All changes follow red-green-refactor:

- **Mailer tests:** Rename existing tests to match `share_property`. Add test for `nil` contact (generic "Bonjour," greeting) and for a real contact (personalized greeting).
- **Controller tests:** Update for rename. Add test that `new` action assigns `@email_preview` containing rendered HTML.
- **Integration:** Verify the share page renders an iframe with the email preview.

## Out of scope

- Changes to the email template design itself
- Background job delivery (currently uses `deliver_now`, unchanged)
- New contact creation from the share page
