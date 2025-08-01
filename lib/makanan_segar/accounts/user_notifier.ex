defmodule MakananSegar.Accounts.UserNotifier do
  import Swoosh.Email

  alias MakananSegar.Mailer
  alias MakananSegar.Accounts.User

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    from_email = "noreply@applikasi.tech"

    email =
      new()
      |> to(recipient)
      |> from(from_email)
      |> subject(subject)
      |> text_body(body)
      |> html_body("""
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #2D3748;">#{subject}</h2>
        <div style="background: #F7FAFC; padding: 20px; border-radius: 8px; white-space: pre-line;">#{body}</div>
        <p style="color: #718096; font-size: 14px; margin-top: 20px;">
          This email was sent from Makanan Segar - Fresh Food Marketplace<br>
          If you didn't request this, please ignore this email.
        </p>
      </div>
      """)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    else
      {:error, reason} ->
        IO.puts("Email delivery failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Update email instructions", """

    ==============================

    Hi #{user.email},

    You can change your email by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end

  @doc """
  Deliver instructions to log in with a magic link.
  """
  def deliver_login_instructions(user, url) do
    case user do
      %User{confirmed_at: nil} -> deliver_confirmation_instructions(user, url)
      _ -> deliver_magic_link_instructions(user, url)
    end
  end

  defp deliver_magic_link_instructions(user, url) do
    name = if user.name && String.trim(user.name) != "", do: user.name, else: user.email

    deliver(user.email, "🔗 Your Magic Login Link - Makanan Segar", """
    Hi #{name},

    Welcome to Makanan Segar! Click the link below to log into your account:

    #{url}

    ⏰ This link will expire in 15 minutes for security.

    Need help? Just reply to this email.

    Best regards,
    Makanan Segar Team
    🥗 Fresh Food Marketplace
    """)
  end

  defp deliver_confirmation_instructions(user, url) do
    name = if user.name && String.trim(user.name) != "", do: user.name, else: user.email

    deliver(user.email, "🎉 Welcome to Makanan Segar - Confirm Your Account", """
    Hi #{name},

    Welcome to Makanan Segar! We're excited to have you join our fresh food marketplace.

    Please confirm your account by clicking the link below:

    #{url}

    Once confirmed, you'll be able to:
    🥬 Browse fresh vegetables from Cameron Highlands
    🐟 Find the freshest seafood from local vendors
    🍎 Discover tropical fruits and local specialties
    💬 Chat directly with vendors about your orders

    Need help? Just reply to this email.

    Best regards,
    Makanan Segar Team
    🥗 Fresh Food Marketplace
    """)
  end

  @doc """
  Test email delivery function for debugging production issues.
  """
  def test_email_delivery(email_address \\ "test@example.com") do
    IO.puts("🧪 Testing email delivery to: #{email_address}")
    IO.puts("📧 From email: noreply@applikasi.tech")
    IO.puts("🔑 Resend API key present: #{(System.get_env("RESEND_API_KEY") && "YES") || "NO"}")

    result =
      deliver(email_address, "🧪 Test Email - Makanan Segar", """
      This is a test email from Makanan Segar.

      If you receive this, email delivery is working correctly!

      Timestamp: #{DateTime.utc_now()}
      Environment: #{System.get_env("MIX_ENV") || "development"}
      Host: #{System.get_env("PHX_HOST") || "localhost"}
      """)

    case result do
      {:ok, email} ->
        IO.puts("✅ Test email sent successfully!")
        IO.puts("📨 Email details: #{inspect(email, pretty: true)}")
        {:ok, "Email sent successfully"}

      {:error, reason} ->
        IO.puts("❌ Test email failed!")
        IO.puts("💥 Error: #{inspect(reason, pretty: true)}")
        {:error, reason}
    end
  end

  @doc """
  Debug function to check mailer configuration
  """
  def debug_mailer_config do
    IO.puts("🔍 Mailer Configuration Debug:")
    IO.puts("  FROM_EMAIL: noreply@applikasi.tech")
    IO.puts("  FROM_FORMAT: email only (no name)")

    IO.puts(
      "  RESEND_API_KEY: #{if System.get_env("RESEND_API_KEY"), do: "SET (#{String.length(System.get_env("RESEND_API_KEY"))} chars)", else: "NOT SET"}"
    )

    IO.puts("  MIX_ENV: #{System.get_env("MIX_ENV") || "development"}")
    IO.puts("  PHX_HOST: #{System.get_env("PHX_HOST") || "localhost"}")

    # Test mailer adapter
    mailer_config = Application.get_env(:makanan_segar, MakananSegar.Mailer, [])
    IO.puts("  Mailer Adapter: #{inspect(mailer_config[:adapter])}")
    IO.puts("  Mailer Config: #{inspect(mailer_config, pretty: true)}")
  end
end
