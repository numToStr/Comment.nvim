function Yo() {
  return (
    <>
      <div>hello</div>
    </>
  );
}

const Yoo = () => {
  return (
    <div>
      <section>
        <p>hello</p>
        <p
          attr={{
            ...window,
            hello: () => {
              return (
                <section>
                  <p>IDK</p>
                </section>
              );
            },
          }}
        >
          hello
        </p>
      </section>
    </div>
  );
};

class Yooo {
  render() {
    return (
      <>
        <div>hello</div>
      </>
    );
  }
}

const Yoooo = () => (
  <>
    <div>hello</div>
  </>
);

const Yoooo = () => (
  <section>
    <div>hello</div>
  </section>
);

function Yoooo() {
  return <div>hello</div>;
}
