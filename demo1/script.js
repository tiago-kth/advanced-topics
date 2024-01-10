const plot = document.querySelector(".plot");
const W = +window.getComputedStyle(plot).width.slice(0,-2);
const H = +window.getComputedStyle(plot).height.slice(0,-2);

const N = 20;
const V = 72;

const w = W / 72;
const h = H / 72;

function pos(val){

    const range = [0, W];
    const domain = [-50,50];

    return range[0] + val * (range[1] - range[0]) / (domain[1] - domain[0])

}

fetch("coil20-data.json").then(response => response.json()).then(data => {

    console.log(w,h, data);

})