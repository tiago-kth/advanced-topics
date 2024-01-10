const plot = document.querySelector(".plot");
const W = +window.getComputedStyle(plot).width.slice(0,-2);
const H = +window.getComputedStyle(plot).height.slice(0,-2);

const colors = ["#F8766D","#EA8331","#D89000","#C09B00","#A3A500","#7CAE00","#39B600","#00BB4E","#00BF7D","#00C1A3","#00BFC4","#00BAE0","#00B0F6","#35A2FF","#9590FF","#C77CFF","#E76BF3","#FA62DB","#FF62BC","#FF6A98"];

const N = 20;
const V = 72;

const l_original = 128;

const w = W / 72;
const h = H / 72;

const gap = 2;

const margin = 20;

function pos_x(val, maxs){

    const range = [margin, W - margin];
    const domain = [-maxs, maxs];

    return ( range[0] + ( val - domain[0] ) * (range[1] - range[0]) / (domain[1] - domain[0]) )

}

function pos_y(val, maxs) {

    const range = [H - margin, margin];
    const domain = [-maxs, maxs];

    return ( range[0] + ( val - domain[0] ) * (range[1] - range[0]) / (domain[1] - domain[0]) )

}

fetch("coil20-data.json").then(response => response.json()).then(data => {

    console.log(w, h, data);

    const perps = [1, 10, 36, 50, 72];

    const maxs = {};

    perps.forEach(perp => {
        maxs["max" + perp] = Math.max(...data.map( d => Math.abs(d["x" + perp]) ) , ...data.map( d => Math.abs(d["y" + perp]) ));
    })

    console.log(maxs);

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
        newDiv.style.transform = `translate(${x}px, ${y}px) scale(var(--s))`;
        newDiv.style.color = colors[v];

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

                x = pos_x(data[i][`x${perp}`], maxs["max" + perp]);
                y = pos_y(data[i][`y${perp}`], maxs["max" + perp]);

            }

            img.style.transform = `translate(${x}px, ${y}px) scale(var(--s))`;

        })

    }

    // monitor

    const btns = document.querySelector('.btns-wrapper');

    // populate the buttons
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