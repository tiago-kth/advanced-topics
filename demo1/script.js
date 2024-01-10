const plot = document.querySelector(".plot");
const W = +window.getComputedStyle(plot).width.slice(0,-2);
const H = +window.getComputedStyle(plot).height.slice(0,-2);

const N = 20;
const V = 72;

const l_original = 128;

const w = W / 72;
const h = H / 72;

const gap = 2;

function pos_x(val){

    const range = [gap, W - gap];
    const domain = [-100,100];

    return ( range[0] - domain[0] + val ) * (range[1] - range[0]) / (domain[1] - domain[0])

}

function pos_y(val) {

    const range = [gap, H - gap];
    const domain = [-100,100];

    return ( range[0] - domain[0] + val ) * (range[1] - range[0]) / (domain[1] - domain[0])

}

fetch("coil20-data.json").then(response => response.json()).then(data => {

    console.log(w, h, data);

    // ---- calcs

    const l1 = ( W - (V + 1) * gap) / V;
    const l2 = ( H - (N + 1) * gap) / N;

    const l = Math.min(l1, l2);

    let f = l / l_original;

    f = Math.floor(f * 10000) / 10000;

    console.log(l1, l2, l, f);

    document.documentElement.style.setProperty('--f', f);

    // ----- //

    // ----- initial layout

    const margin_H = H - ( l * N ) - ( gap * (N + 1) );
    const margin_top = margin_H / 2;

    const margin_W = W - ( l * V ) - ( gap * (V + 1) );
    const margin_left = margin_W / 2;

    // ---- add imgs

    const cont = document.querySelector(".plot");

    data.forEach( (p, i) => {

        const newDiv = document.createElement('div');

        const u = +p.view;
        const v = +p.label - 1;

        const x = margin_left + (gap + l) * u;
        const y = margin_top + (gap + l) * v;

        newDiv.classList.add('img');
        newDiv.dataset.index = i;
        newDiv.dataset.label = p.label;
        newDiv.dataset.x0 = x;
        newDiv.dataset.y0 = y;
        newDiv.style.setProperty('--i', u);
        newDiv.style.setProperty('--j', v);
        newDiv.style.transform = `translate(${x}px, ${y}px) scale(var(--f))`

        cont.appendChild(newDiv);

    })

    const imgs = document.querySelectorAll('.img');

    function applyPerplexity(perp) {

        // perps: 1, 10, 36, 50, 72

        imgs.forEach( (img,i) => {

            let x,y;

            if (perp == 'back') {

                x = img.dataset.x0;
                y = img.dataset.y0;

            } else {

                x = pos_x(data[i][`x${perp}`]);
                y = pos_y(data[i][`y${perp}`]);

            }

            img.style.transform = `translate(${x}px, ${y}px) scale(var(--f))`;

        })

    }

    // monitor

    const btns = document.querySelector('.btns-wrapper');

    // populate the buttons
    const perps = [1, 10, 36, 50, 72];
    perps.forEach(p => {

        const newButton = document.createElement('button');
        newButton.classList.add('btn');
        newButton.dataset.perp = p;
        newButton.innerText = 'Perplexity: ' + p;
        btns.appendChild(newButton);

    })

    btns.addEventListener('click', clicked);

    function clicked(e) {

        if (e.target.tagName == 'BUTTON') {

            console.log('opa');

            const btn = e.target;
            const perp = btn.dataset.perp;

            applyPerplexity(perp);

        }

    }

    // control display

    const selectControl = document.querySelector('#control-display');
    selectControl.addEventListener('change', e => {
        cont.classList.toggle('no-img');
    })

})