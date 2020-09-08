/*
This small script simply finds the latest message from the bot
and dumps it to a div that can be accessed by the Apple Script.
*/

const botName = 'BotName';
const userName = document.querySelector('div[class*="usernameContainer"]').innerText;
const pulse = 100;

const newWatchContainer = id => {
    const newContainer = document.createElement('div');
    newContainer.style.cssText = 'background: white; position: absolute; top: 0; left: 0; zIndex: 999999; display: none;';
    newContainer.id = id;
    return document.body.appendChild(newContainer);
}

const getBotStatus = () => {
    // Grab all messages and regress until correct bot status is found.
    let allMessages = document.querySelectorAll('[class^="message"]');
    for (let i = 1; i < allMessages.length; i++) {
            const message = allMessages[allMessages.length - i]; // From new to old.
            const user = message.querySelector('[class^="username"]');
            // Check to make sure that this message is from the bot AND to the user.
            // TODO: This is not very robust (ex: another user will trigger if they have the same name.)
            if (user.innerText === botName && message.innerText.indexOf(userName) !== -1) return message.innerText;
    }
    // None found, uh oh.
    return false;
}

const saveStatus = (container, status) => {
    container.innerText = status();
}

const target = newWatchContainer('watchbot');

setInterval(() => saveStatus(target, getBotStatus), pulse);
