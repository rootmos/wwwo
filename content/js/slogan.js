(function() {
    let sloganElement;

    let slogans = [
        "I trust,&nbspbut verify",
        "I like silly things and abstract non-sense",
        "I like silly things<br/>but I'm dead serious about code",
        "I like silly things<br/>but I'm dead serious about code<br/>and ruthlessly (self-)critical",
    ];
    let next = 0;

    function createObserver() {
          let observer = new IntersectionObserver(handleIntersect, {
              root: null,
              rootMargin: "0px",
              threshold: [ 0.0 ],
          });

          observer.observe(sloganElement);
    }

    function handleIntersect(entries, observer) {
        if(entries.length != 1 || entries[0].target != sloganElement) {
            throw new Error(`unexpected entries`)
        }

        if(entries[0].intersectionRatio > 0) {
            return;
        }

        sloganElement.innerHTML = slogans[next%slogans.length];
        next += 1;
    }

    window.addEventListener(
        "load",
        ev => {
            sloganElement = document.querySelector("#slogan-text");
            slogans.push(sloganElement.innerHTML);
            console.log(slogans);
            createObserver();
        },
        false,
    );
})()
