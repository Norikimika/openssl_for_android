import os
import sys
import requests

def main():
    if len(sys.argv) < 2:
        print("Usage: python errorbot.py <file_path>")
        sys.exit(1)

    file_path = sys.argv[1]

    # Load environment variables
    bot_token = os.environ["TELEGRAM_BOT_TOKEN"]
    chat_id = os.environ["TELEGRAM_CHAT_ID"]
    topic_id = os.environ.get("TELEGRAM_TOPIC_ID")
    openssl_version = os.environ.get("OPENSSL_VERSION", "Unknown")
    ndk_version = os.environ.get("NDK_VERSION", "Unknown")

    # HTML caption
    caption = (
        "<b>✹ OpenSSL Version</b>\n"
        f"<i>-> {openssl_version}</i>\n"
        "<b>✹ NDK Version</b>\n"
        f"<i>-> {ndk_version}</i>\n"
    )

    url = f"https://api.telegram.org/bot{bot_token}/sendDocument"

    try:
        with open(file_path, "rb") as doc:
            files = {"document": doc}
            data = {
                "chat_id": chat_id,
                "caption": caption,
                "parse_mode": "HTML"
            }
            if topic_id:
                data["message_thread_id"] = topic_id

            response = requests.post(url, files=files, data=data)

        if response.ok:
            print(f"Successfully sent: {file_path}")
        else:
            print(f"Failed to send {file_path}. Telegram response:\n{response.text}")
            sys.exit(1)

    except Exception as e:
        print(f"An error occurred while sending {file_path}: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()