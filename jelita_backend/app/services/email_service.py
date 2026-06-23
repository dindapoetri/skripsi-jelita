import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from app.core.config import settings


def send_reset_password_email(to_email: str, reset_token: str) -> None:
    """
    Kirim email berisi token/link reset password via SMTP.
    Token ditempelkan sebagai deep link agar bisa langsung dibuka di app Flutter.
    """
    subject = "Reset Password - Jelita Skincare"
    reset_link = f"jelita://reset-password?token={reset_token}"

    body = f"""
    <html>
      <body>
        <p>Halo,</p>
        <p>Kami menerima permintaan reset password untuk akun Jelita Skincare kamu.</p>
        <p>Kode reset password kamu (berlaku {settings.RESET_TOKEN_EXPIRE_MINUTES} menit):</p>
        <h2>{reset_token}</h2>
        <p>Atau klik link berikut jika dibuka dari HP yang sama:</p>
        <p><a href="{reset_link}">{reset_link}</a></p>
        <p>Jika kamu tidak meminta ini, abaikan saja email ini.</p>
      </body>
    </html>
    """

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = f"{settings.SMTP_FROM_NAME} <{settings.SMTP_FROM_EMAIL}>"
    msg["To"] = to_email
    msg.attach(MIMEText(body, "html"))

    with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as server:
        server.starttls()
        server.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
        server.sendmail(settings.SMTP_FROM_EMAIL, to_email, msg.as_string())