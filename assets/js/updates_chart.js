

export default {
    loadChart(el, keys, values) {
        new Chart(el, {
            type: 'bar',
            data: {
                labels: keys,
                datasets: [{
                    label: '# of Published Updates',
                    data: values,
                    backgroundColor: [
                        '#505050',
                    ],
                }]
            }
        });
    },
   
    mounted() {
        let parent = this;

        this.handleEvent("chart_data", ({keys, values}) => parent.loadChart(parent.el, keys, values))        
    },
}