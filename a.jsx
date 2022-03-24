const Yoo = () => {
  return (
    <div>
      <section>
        <p>hello</p>
        <p
          he="llo"
          wor="ld"
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
        <p>{true ? "true" : "false"}</p>
        <p>{true && "true"}</p>
        <p>
          {true && (
            <section>
              <p>This is awesome</p>
            </section>
          )}
        </p>
        <div id="div">
          {getUser({
            name: "numToStr",
            job: "making plugins",
          })}
        </div>
      </section>
    </div>
  );
};
//
// const Yoooo = () => (
//   <section>
//     <div>hello</div>
//   </section>
// );
//
// function Yo() {
//   return (
//     <>
//       <div>hello</div>
//     </>
//   );
// }
//
// class Yooo {
//   render() {
//     return (
//       <>
//         <div>hello</div>
//       </>
//     );
//   }
// }
//
// const Yoooo = () => (
//   <>
//     <div>hello</div>
//   </>
// );
//
// function Yoooo() {
//   return <div>hello</div>;
// }
