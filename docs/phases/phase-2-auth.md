# Phase 2 — Authentication

**Status: ✅ Completed**

**Objective:** Implement session-based login/register matching the reference login screen, and protect all app routes behind authentication.

**Dependencies:** Phase 1 (Tailwind, layouts, PostgreSQL)

**Reference:** `project-blueprint-studio/src/pages/LoginPage.tsx`

---

## 2.1 User Model

### Migration

```ruby
create_table :users do |t|
  t.string :email, null: false
  t.string :name, null: false
  t.string :password_digest, null: false

  t.timestamps
end

add_index :users, :email, unique: true
```

### Model

**app/models/user.rb:**
```ruby
class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 6 }, on: :create
end
```

Uses `bcrypt` gem (uncommented in Phase 1).

---

## 2.2 Authentication Concern

**app/controllers/concerns/authentication.rb:**

```ruby
module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :logged_in?
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def authenticate_user!
    unless logged_in?
      redirect_to login_path, alert: "Debes iniciar sesion para acceder"
    end
  end
end
```

Include in `ApplicationController` with `before_action :authenticate_user!`.

---

## 2.3 Controllers

### SessionsController

**app/controllers/sessions_controller.rb:**

| Action | Method | Path | Description |
|--------|--------|------|-------------|
| `new` | GET | `/login` | Render login form |
| `create` | POST | `/login` | Authenticate and create session |
| `destroy` | DELETE | `/logout` | Clear session |

- `new`: renders the login page (uses `public` layout)
- `create`: finds user by email, authenticates password, sets `session[:user_id]`, redirects to `/dashboard`
- `destroy`: resets session, redirects to `/login`
- Skip `authenticate_user!` for `new` and `create`

### RegistrationsController

**app/controllers/registrations_controller.rb:**

| Action | Method | Path | Description |
|--------|--------|------|-------------|
| `new` | GET | `/register` | Render register form |
| `create` | POST | `/register` | Create user and log in |

- `new`: renders the register page (uses `public` layout)
- `create`: creates user, sets `session[:user_id]`, redirects to `/dashboard`
- Skip `authenticate_user!` for `new` and `create`

---

## 2.4 Routes

```ruby
# Auth routes
get "login", to: "sessions#new"
post "login", to: "sessions#create"
delete "logout", to: "sessions#destroy"
get "register", to: "registrations#new"
post "register", to: "registrations#create"
```

---

## 2.5 Login/Register View

**app/views/sessions/new.html.erb** (uses `public` layout):

Port from `LoginPage.tsx`:

- Centered card on dark background
- Glow background effect (fixed `div` with `bg-primary/8 blur-[100px]`)
- Back link: "Volver al inicio" pointing to `/`
- Logo: LIDR RAG Estimator with Activity icon and version
- Card with:
  - Title: "Iniciar sesion" (login) / "Crear cuenta" (register)
  - Subtitle: "Accede a tu panel de estimaciones" / "Registrate para empezar a estimar proyectos"
  - Toggle between login/register via Turbo Frame or link to separate pages
  - Name field (register only)
  - Email field
  - Password field with visibility toggle (Stimulus controller)
  - Submit button: "Entrar" / "Crear cuenta"
  - Toggle link: "No tienes cuenta? Registrate" / "Ya tienes cuenta? Inicia sesion"

### Approach: Separate pages vs Turbo Frame toggle

**Option A (simpler):** Two separate pages (`/login` and `/register`) with links between them.
**Option B (matches React):** Single page with Turbo Frame that swaps the form content.

Recommended: **Option A** for simplicity. Each page links to the other.

---

## 2.6 Stimulus Controllers

### password-toggle controller

**app/javascript/controllers/password_toggle_controller.js:**

- Targets: `input` (the password field), `icon` (the toggle button)
- Action: `toggle` — switches input type between "password" and "text", swaps eye/eye-off icon

---

## Files to Create/Modify

| Action | File |
|--------|------|
| Create | `db/migrate/xxx_create_users.rb` |
| Create | `app/models/user.rb` |
| Create | `app/controllers/concerns/authentication.rb` |
| Create | `app/controllers/sessions_controller.rb` |
| Create | `app/controllers/registrations_controller.rb` |
| Create | `app/views/sessions/new.html.erb` |
| Create | `app/views/registrations/new.html.erb` |
| Create | `app/javascript/controllers/password_toggle_controller.js` |
| Modify | `app/controllers/application_controller.rb` (include Authentication, before_action) |
| Modify | `config/routes.rb` (add auth routes) |

---

## Verification

1. `rails db:migrate` creates users table
2. Visit `/register` — form renders with name, email, password fields
3. Submit registration — user created, redirected to `/dashboard`
4. Visit `/logout` — session cleared, redirected to `/login`
5. Visit `/login` — form renders with email, password fields
6. Submit login — authenticated, redirected to `/dashboard`
7. Visit `/dashboard` without session — redirected to `/login`
8. Password toggle button shows/hides password
