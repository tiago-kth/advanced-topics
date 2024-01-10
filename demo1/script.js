const plot = document.querySelector(".plot");
const W = +window.getComputedStyle(plot).width.slice(0,-2);
const H = +window.getComputedStyle(plot).height.slice(0,-2);

const N = 20;
const V = 72;

const l_original = 128;

const w = W / 72;
const h = H / 72;

const gap = 2;

function pos(val){

    const range = [0, W];
    const domain = [-100,100];

    return range[0] + val * (range[1] - range[0]) / (domain[1] - domain[0])

}

fetch("coil20-data.json").then(response => response.json()).then(data => {

    console.log(w, h, data);

    const l1 = ( W - (V + 1) * gap) / V;
    const l2 = ( H - (N + 1) * gap) / N;

    const l = Math.min(l1, l2);

    let f = l / l_original;

    f = Math.floor(f * 10000) / 10000;

    console.log(l1, l2, l, f);

    document.documentElement.style.setProperty('--f', f);



})