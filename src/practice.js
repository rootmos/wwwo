var data = data.map(function(e) {
    return { date: moment(e.date), minutes: e.minutes };
});

function render(last_n_days) {
    var ds = [];
    if(last_n_days) {
        for(d = moment().subtract(last_n_days, "days"); d.isSameOrBefore(moment(), "day"); d.add(1, "day")) {
            var e = data.find(function (e) { return e.date.isSame(d, "day"); });
            if(e) {
                ds.push({x: e.date, y: e.minutes});
            } else {
                ds.push({x: d.clone(), y: 0.0});
            }
        }
    } else {
        ds = data.map(function (e) { return {x: e.date, y: e.minutes}; });
    }

    new Chart(document.getElementById("chart"), {
        type: "bar",
        data: {
            datasets: [{
                label: "minutes",
                data: ds,
                backgroundColor: "rgba(204, 51, 255, 0.2)",
                borderColor: "rgba(204, 51, 255, 1)",
                borderWidth: 2,
                fill: true,
            }]
        },
        options: {
            scales: {
                xAxes: [{
                    type: "time",
                    time: { unit: "day" }
                }]
            }
        }
    });
}

render(7);
