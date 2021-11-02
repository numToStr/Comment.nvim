export function tick() {
    const element = (
        <div>
            <h1
                id="hello"
                class="broo"
                data-foo="foo"
                data-telescope="good"
                data-data="fhfhfhfhfhfhhfhfh"
            >
                Hello, world!
            </h1>
            <h2 id="hello2">It is {new Date().toLocaleTimeString()}.</h2>
        </div>
    );

    ReactDOM.render(element, document.getElementById("root"));
}
