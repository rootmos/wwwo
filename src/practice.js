var ctx = document.getElementById("myChart").getContext("2d");
var myChart = new Chart(ctx, {
    type: 'bar',
    data: {
        labels,
        datasets: [{
            label: 'minutes',
            data,
            backgroundColor: 'rgba(204, 51, 255, 0.2)',
            borderColor: 'rgba(204, 51, 255, 1)',
            borderWidth: 2
        }]
    },
    options: {
        scales: {
            yAxes: [{
                ticks: {
                    beginAtZero: true
                }
            }]
        }
    }
});
