const express = require('express');
const bodyParser = require('body-parser');
const fs = require('fs');
const os = require('os');
const { spawn } = require('child_process');
const ngrok = require('ngrok');
const { dirname } = require('path');
const { error } = require('console');
const { buffer } = require('stream/consumers');
const { Worker } = require('node:worker_threads');
require('dotenv').config();


let base64LabelArray = [];
let bufferImages =[];
let totalSaved = 0;
let printLabels;
let salesOrderNo;
let iType;

const ngrokWorker = new Worker('./ngrokWorker.js');
const PORT = process.env.PORT;
const app = express();


app.use(bodyParser.json({limit: '10mb'}));

app.get('/',(req,res) => {
    res.send('Fedex-BC integration');
    return;
})

app.post('/create_directory', async (req,res) =>{
    const{salesOrderNumber} = req.body;
    setSalesOrderNumber(salesOrderNumber);

    await makeDir().then(rootCreation =>{
        if(!rootCreation.ok){
            res.status(405).send({
                message : rootCreation.message
            });
            return;
        }
    });

    await checkDirForOrder().then(options =>{
        if(!options.ok){
            res.status(405).send({
                message : options.message
            });
            return;                
        } else {
            res.status(200).send({
                message : options.message
            })
            return;
        }
    });
})

app.post('/print_labels',async (req,res)=>{
    const{labels} = req.body;
    setLabels(labels);
    const{salesOrderNumber} = req.body;
    setSalesOrderNumber(salesOrderNumber);
    const{imageType}  = req.body;
    setImageType(imageType);

    if(labels == undefined){
        res.status(403).res.send({
            message : 'base64 Image not received, please check your input and resend.'
        })
        return;
    } 

    await base64Processing(printLabels);
    await decodeLabels();
    for(var i = 0; i < bufferImages.length; i++){
        await saveImage(bufferImages[i], i + 1)
    }
    await produceBatFile();
    if(totalSaved != labels.length){
        res.status(200).send({
            message : totalSaved + " out of " + labels.length + " labels saved."
        })
        resetVariables();
        return;
    } else {
        res.status(200).send({
            message : totalSaved + ' out of ' + labels.length + ' labels saved.'
        })
        resetVariables();
        return;
    }

})

app.put('/clear_directory', async (req,res) =>{
    const{salesOrderNumber} = req.body;
    setSalesOrderNumber(salesOrderNumber);

    if (fs.existsSync('./Fedex_BC_Labels/' + salesOrderNo)){
        await clearDirForOrder().then(directoryCleared =>{
        if(!directoryCleared.ok){
                res.status(405).send({
                    message : directoryCleared.message
                })
                return;
            } else {
                res.status(200).send({
                    message: directoryCleared.message
                })
                return
            }
        });
    } else {
        res.status(405).send({
            message : "Cannot find directory."
        })
        return;
    }
})

async function resetVariables(){
    base64LabelArray = [];
    bufferImages = [];
    totalSaved = 0;
}

async function setLabels(labels){
    printLabels = labels;
}

async function setSalesOrderNumber(orderNumber){
    salesOrderNo = orderNumber;
}

async function setImageType(type){
    switch(type){
        case 'PDF':
            iType = 'pdf';
            break;
        case 'PNG':
            iType = 'png';
            break;
        case 'ZPLII':
            iType = 'zpl';
            break;
        case 'EPL2':
            iType = 'epl';
            break;
        default:
            console.error('Cannot recognize imagetype. please contact administrator for assitance.');
    } 
}

async function makeDir(){
    let rootCreation;
    if (fs.existsSync('./Fedex_BC_Labels')){
            rootCreation = {
                "ok" : true,
                "message" : "Root directory exists"
            }
        console.log('Fedex_BC_Labels folder exists');
    } else {
        fs.mkdir('./Fedex_BC_Labels', (err) =>{
            if(err){
                if(err.errno != -4075) {
                    console.log(err);
                }
                rootCreation = {
                    "ok" : false,
                    "message" : "Root directory creation error: " + err.message
                }
                return;
            }
        });
        rootCreation = {
            "ok" : true,
            "message" : "Root directory created successfully."
        }

    }
    return rootCreation;

}

async function clearDirForOrder(){
    let fileDir = './Fedex_BC_Labels/' + salesOrderNo;
    let directoryExists;
    if(fs.existsSync(fileDir)){
        fs.rm(fileDir,{recursive: true, force: true}, (err) =>{
            if(err){
                console.log(err);
            } else {
                console.log('folder ' + salesOrderNo + ' deleted.');
            }
        })
        directoryExists = {
            "ok" : true,
            "message" : "directory " + fileDir + " deleted."
        };
    } else {
        directoryExists = {
            "ok" : false,
            "message" : "nothing to delete."
        };
    }
    return directoryExists;
}

async function checkDirForOrder(){
    let fileDir = './Fedex_BC_Labels/' + salesOrderNo;
    let directoryExists;
    if(!fs.existsSync(fileDir)){
        fs.mkdir(fileDir, (err) =>{
            if(err){
                console.log(err.message);
                directoryExists = {
                    "ok" : false,
                    "message" : "Directory Creation Error: " + err.message + "\nPlease contact administrator."
                }
                return directoryExists;
            }
        });
        console.log('file ' + fileDir + ' created');
        directoryExists = {
            "ok" : true,
            "message" : "file directory " + fileDir + " created."
        }
        return directoryExists;
    } else {
        directoryExists = {
            "ok" : true,
            "message" : fileDir + " ready."
        }
        return directoryExists;
    }
}

async function mkPrintfilesDir(){
    let printfileDir = './Printfiles/';
    let directoryExists;
    if(!fs.existsSync(printfileDir)){
        fs.mkdir(printfileDir, (err) =>{
            if(err){
                console.log(err.message);
                directoryExists = {
                    "ok" : false,
                    "message" : "Directory Creation Error: " + err.message + "\nPlease contact administrator."
                }
                return directoryExists;
            }
        });
        console.log('file ' + printfileDir + ' created');
        directoryExists = {
            "ok" : true,
            "message" : "file directory " + printfileDir + " created."
        }
        return directoryExists;
    } else {
        directoryExists = {
            "ok" : true,
            "message" : printfileDir + " ready."
        }
        return directoryExists;
    }
}

async function base64Processing(labels) {
    for(var i = 0; i < labels.length; i++){
        const {EncodedLabel} = labels[i];
        EncodedLabel.replace(/^EncodedLabel:\/\w+;base64,/, ''); 
        base64LabelArray.push(EncodedLabel);
    }
}

async function decodeLabels(){
    for(var i = 0; i < base64LabelArray.length; i++){
        decodeBase64(base64LabelArray[i]);
    }
}

async function decodeBase64(base64Data){
    var buf1 = Buffer.from(base64Data,'base64');
    bufferImages.push(buf1);
}

async function saveImage(buf1, index){
    let imageSaved = 0;
    fs.writeFile('./Fedex_BC_Labels/'+ salesOrderNo + '/label' + index + '.' + iType, buf1, (err) => {
        if(err) {
            console.log('Error: ', err + ' occured with label ' + index + ' in folder ' + os.homedir + '/Desktop/Fedex_BC_Labels/'+ salesOrderNo);
            return;
        } 
    })
    console.log('label ' + index + ' saved to folder ' + os.homedir + '/Desktop/Fedex_BC_Labels/'+ salesOrderNo);
    imageSaved = 1;
    totalSaved = totalSaved + imageSaved;
}


async function produceBatFile(){
    const script = 'cd /d "%~dp0"\n@echo off\nsetlocal\n\n@echo starting process...\n\nset "folder=' + '../Fedex_BC_Labels/'+ salesOrderNo + '"\nset "printer=TSC DA210"\n\n@echo Default printer set to %printer%\n\nRUNDLL32 PRINTUI.DLL,PrintUIEntry /y /n "%printer%"\n\nfor %%f in ("%folder%\\*.png") do (\n' + '    mspaint /pt "%%f" "%printer%"'  + '\n' + '    @echo printed %%f\n' + '    timeout /t 5 >nul' + '\n' + ')\n\n' + '@echo Default Task Complete!\n exit 0';
    fs.writeFile('./Printfiles/printfile_' + salesOrderNo + '.bat', script, (err) =>{
        if(err){
            console.log('printfile Error: ', err);
        } else {
            console.log('Print file for ' + salesOrderNo + ' successfully deployed');
        }
    })
    executePrintFile();
}

async function executePrintFile(){
    const printer = spawn('cmd.exe', ['/c', 'start "" "' + os.homedir + '\\Desktop\\fedex-bc-printer\\Printfiles\\printfile_' + salesOrderNo + '.bat"'], {
    shell: true
    });

    printer.stdout.on('data', data =>{
        console.log('Output: %d', data);
    });

    printer.stderr.on('data', data => {
    console.log('Error: %d', data);
    })
}

app.listen(PORT, ()=>{
    console.log('Fedex print server running on port: ', PORT);
    mkPrintfilesDir();
    
    ngrokWorker.addListener('error', (nwerror) => {
        console.log('Ngrok Error: ' + nwerror);
    })

    ngrokWorker.addListener('message', (nwmessage)=>{
        console.log('Ngrok message: ' + nwmessage);
    })

    ngrokWorker.addListener('messageerror', (nwmessageerror)=>{
        console.log('Ngrok message error: ' + nwmessageerror);
    })
})