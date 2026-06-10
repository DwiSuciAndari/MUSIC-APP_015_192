const btn = document.getElementById("sendBtn");

btn.addEventListener("click", sendMessage);

function formatText(text) {
    return text
        .replace(/\n/g, "<br>")
        .replace(/\*\*(.*?)\*\*/g, "<b>$1</b>");
}

async function sendMessage() {
    const input = document.getElementById("message");
    const text = input.value;

    if (!text) return;

    const chatBox = document.getElementById("chat-box");

    chatBox.innerHTML += `<div class="user">${text}</div>`;

    input.value = "";

    chatBox.innerHTML += `<div class="bot">DSAI lagi mikir...</div>`;

    try {
        const res = await fetch("/api/chat", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({ message: text })
        });

        const data = await res.json();

        chatBox.lastChild.remove();

        chatBox.innerHTML += `<div class="bot">${formatText(data.result)}</div>`;

    } catch (err) {
        chatBox.innerHTML += `<div class="bot">Server error 😭</div>`;
    }
}