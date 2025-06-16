let avatar_revealed = 0;
let avatar_clicks = 0;

function avatar_show_hint() {
    if(!avatar_revealed) {
        document.getElementById('avatar-hint').style['display'] = 'block';
    }
}

setTimeout(avatar_show_hint, 5000);

function avatar_onclick() {
    document.getElementById('avatar-hint').style['display'] = 'none';
    const e1 = document.getElementById('avatar-explanation-1');
    const e2 = document.getElementById('avatar-explanation-2');
    if(avatar_clicks%4 == 0) {
        e1.style['display'] = 'block';
    } else if(avatar_clicks%4 == 1) {
        e2.style['display'] = 'block';
    } else if(avatar_clicks%4 == 2) {
        e2.style['display'] = 'none';
    } else {
        e1.style['display'] = 'none';
    }
    avatar_clicks += 1;
    avatar_revealed = 1;
}
