const NativeBridge = process._linkedBinding('SwiftBridge');

const { IgApiClient } = require('instagram-private-api');
const ig = new IgApiClient();

var isLoggingIn = false;

NativeBridge.doSomethingUseful((msg, cb) => {
    function callback(result, error) {
        var info = {
        type: msg.type,
        error: error,
        };
        info[msg.type] = result;
        cb(info);
    }
    
    switch (msg.type) {
        case 'login':
            if (isLoggingIn) {
                console.log('already logging in!');
                return;
            }
            isLoggingIn = true;
            console.log('logging in...');
            ig.state.generateDevice(msg.username);
            console.log('generated device');
            (async () => {
                // Execute all requests prior to authorization in the real Android application
                // Not required but recommended
                await ig.simulate.preLoginFlow();
                try {
                    const loggedInUser = await ig.account.login(msg.username, msg.password);
                    isLoggingIn = false;
                    console.log('logged in');
                    // The same as preLoginFlow()
                    // Optionally wrap it to process.nextTick so we dont need to wait ending of this bunch of requests
                    process.nextTick(async () => await ig.simulate.postLoginFlow());
                    callback(loggedInUser);
                } catch (error) {
                    isLoggingIn = false;
                    console.log(error);
                    callback(null, error);
                }
            })();
            break;
        case 'timeline':
            (async () => {
                timeline = ig.feed.timeline();
                const firstPage = await timeline.items();
                callback(firstPage);
            })();
            break;
        case 'loadNext':
            (async () => {
                const nextPage = await timeline.items();
                callback(nextPage);
            })();
            break;
        default:
            console.log('unknown message: ' + msg.type);
            callback({
            foo: "a",
            bar: 1,
                //          t2: {
                //              baz: "b"
                //          }
            });
            break;
    }
});
