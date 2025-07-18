const ngrok = require('ngrok');

(async function() {
		const listener = await ngrok.connect({
				// The port your app is running on.
				addr: 3000,
				authtoken: process.env.NGROK_AUTHTOKEN,
				domain: "perch-moral-purely.ngrok-free.app",
				// Secure your endpoint with a traffic policy.
				// This could also be a path to a traffic policy file.
				traffic_policy: ''
		});

		// Output ngrok url to console
		console.log(`Ingress established at ${listener.url()}`);
})();

// Keep the process alive
process.stdin.resume();