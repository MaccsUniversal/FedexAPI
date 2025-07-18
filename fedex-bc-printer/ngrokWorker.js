const { spawn } = require('child_process');
const { exec } = require('child_process');
const { parentPort } = require('worker_threads');
require('dotenv').config();

const authtoken = process.env.NGROK_AUTHTOKEN;
const port = process.env.PORT;

exec('ngrok config add-authtoken ' + authtoken, (error,stdout,stderr)=>{
    if(error){
        parentPort.postMessage(error);
        console.log(error);
    }
    if(stdout){
        parentPort.postMessage(stdout);
        console.log(stdout);
    }
    if(stderr){
        parentPort.postMessage(stderr);
        console.log(stderr);
    }

});
    // ngrokAuth.stdout.on('data', data =>{
    //     console.log('Output: %d', data);
    //     // parentPort.postMessage(data);
    // });

    // ngrokAuth.stderr.on('data', data => {
    //     console.log('Error: %d', data);
    //     // parentPort.postMessage(data);
    // });

const ngrokServer = spawn('cmd.exe',['/c','start "" ngrok http --url=perch-moral-purely.ngrok-free.app ' + port],{shell: true});
    ngrokServer.stdout.on('data', data =>{
        console.log('Output: %d', data);
        parentPort.postMessage(data);
    });

    ngrokServer.stderr.on('data', data => {
        console.log('Error: %d', data);
        // parentPort.postMessage(data);
    });
