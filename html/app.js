const DATA = {
    contacts: [
        {
            id: 'snake',
            name: 'SNAKE',
            items: [
                { name: 'COLT 1911', price: 2500 },
                { name: 'UZI', price: 7500 },
                { name: 'AMMO BOX', price: 400 }
            ]
        },
        {
            id: 'ghost',
            name: 'GHOST',
            items: [
                { name: 'LOCKPICK', price: 150 },
                { name: 'LAPTOP', price: 5000 },
                { name: 'DRILL', price: 1200 }
            ]
        }
    ],
    replies: ['SHOW ME WHAT YOU GOT', 'WHO ARE YOU?', 'NEVERMIND']
};

let state = {
    view: 'CONTACTS',
    index: 0,
    contact: null,
    chat: [],
    typing: false,
    item: null
};

const $content = $('#main-content');

function draw() {
    $content.html('');

    if (state.view === 'CONTACTS') {
        $('#btn-left').text('OPEN');
        $('#btn-right').text('EXIT');

        $content.append(`<div class="view-header">CONTACTS</div>`);

        let list = $('<div class="item-list"></div>');
        DATA.contacts.forEach((c,i)=>{
            list.append(`<div class="list-row ${state.index===i?'selected':''}">${c.name}</div>`);
        });
        $content.append(list);
    }

    if (state.view === 'CHAT') {
        $('#btn-left').text('REPLY');
        $('#btn-right').text('BACK');

        $content.append(`<div class="view-header">${state.contact.name}</div>`);

        let log = $('<div class="chat-log"></div>');
        state.chat.forEach(m=>{
            log.append(`<div class="bubble ${m.from}">${m.text}</div>`);
        });
        if (state.typing) log.append(`<div class="typing">TYPING...</div>`);
        $content.append(log);
        log.scrollTop(log[0].scrollHeight);
    }

    if (state.view === 'REPLY') {
        $('#btn-left').text('SEND');
        $('#btn-right').text('CANCEL');

        drawChatBg();

        let tray = $('<div class="action-tray"></div>');
        DATA.replies.forEach((r,i)=>{
            tray.append(`<div class="list-row ${state.index===i?'selected':''}">${r}</div>`);
        });
        $content.append(tray);
    }

    if (state.view === 'CATALOG') {
        $('#btn-left').text('BUY');
        $('#btn-right').text('BACK');

        $content.append(`<div class="view-header">STOCK LIST</div>`);

        let list = $('<div class="item-list"></div>');
        state.contact.items.forEach((it,i)=>{
            list.append(`
                <div class="list-row ${state.index===i?'selected':''}">
                    <span>${it.name}</span>
                    <span>$${it.price}</span>
                </div>
            `);
        });
        $content.append(list);
    }

    if (state.view === 'CONFIRM') {
        $('#btn-left').text('YES');
        $('#btn-right').text('NO');

        $content.append(`<div class="view-header">CONFIRM</div>`);
        $content.append(`
            <div style="text-align:center;padding:20px;font-size:14px">
                PURCHASE<br>
                <b>${state.item.name}</b><br>
                FOR $${state.item.price}?
            </div>
        `);
    }
}

function drawChatBg() {
    $content.append(`<div class="view-header">${state.contact.name}</div>`);
    let log = $('<div class="chat-log"></div>');
    state.chat.forEach(m=>{
        log.append(`<div class="bubble ${m.from}">${m.text}</div>`);
    });
    $content.append(log);
    log.scrollTop(log[0].scrollHeight);
}

function input(key) {
    let up = ['w','W','ArrowUp'];
    let down = ['s','S','ArrowDown'];
    let ok = ['Enter','e','E','d','D'];
    let back = ['Backspace','Escape','q','Q','a','A'];

    let max = 0;
    if (state.view === 'CONTACTS') max = DATA.contacts.length;
    if (state.view === 'REPLY') max = DATA.replies.length;
    if (state.view === 'CATALOG') max = state.contact.items.length;

    if (up.includes(key) && max)
        state.index = state.index>0 ? state.index-1 : max-1;

    if (down.includes(key) && max)
        state.index = state.index<max-1 ? state.index+1 : 0;

    if (ok.includes(key)) {
        if (state.view === 'CONTACTS') {
            state.contact = DATA.contacts[state.index];
            state.chat = [{from:'dealer',text:'YO. WHAT YOU NEED?'}];
            state.view = 'CHAT';
            state.index = 0;
        }
        else if (state.view === 'CHAT') {
            state.view = 'REPLY';
            state.index = 0;
        }
        else if (state.view === 'REPLY') {
            let r = DATA.replies[state.index];
            state.chat.push({from:'me',text:r});
            state.view = 'CHAT';
            state.typing = true;

            if (r === 'SHOW ME WHAT YOU GOT') {
                setTimeout(()=>{
                    state.typing = false;
                    state.view = 'CATALOG';
                    state.index = 0;
                    draw();
                },1500);
                return;
            }

            setTimeout(()=>{
                state.typing = false;
                state.chat.push({from:'dealer',text:'GET LOST THEN.'});
                draw();
            },1000);
        }
        else if (state.view === 'CATALOG') {
            state.item = state.contact.items[state.index];
            state.view = 'CONFIRM';
        }
        else if (state.view === 'CONFIRM') {
            state.chat.push({
                from:'dealer',
                text:`COORDS SENT FOR ${state.item.name}. CHECK YOUR GPS.`
            });
            state.view = 'CHAT';
        }
    }

    if (back.includes(key)) {
        if (state.view === 'CHAT') state.view = 'CONTACTS';
        else if (state.view === 'REPLY') state.view = 'CHAT';
        else if (state.view === 'CATALOG') state.view = 'CHAT';
        else if (state.view === 'CONFIRM') state.view = 'CATALOG';
        state.index = 0;
    }

    draw();
}

$(window).on('keydown', e => input(e.key));

setInterval(()=>{
    let d = new Date();
    $('#clock').text(
        d.getHours().toString().padStart(2,'0') + ':' +
        d.getMinutes().toString().padStart(2,'0')
    );
},1000);

draw();

