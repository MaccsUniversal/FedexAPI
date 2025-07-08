const express = require('express');
const bodyParser = require('body-parser');
const printer = require('printer');
const fs = require('fs');
const os = require('os');
const { dirname } = require('path');


const labelArray = [];
let salesOrderNo;
let iType;
let labelStock;

const app = express();
const PORT = '3000';

app.use(bodyParser.json({limit: '10mb'}));

app.get('/',(req,res) => {
    res.send('Fedex-BC integration');
})

app.post('/print',async (req,res,next)=>{
    const{labels} = req.body;
    const{salesOrderNumber} = req.body;
    const{imageType} =req.body;
    if(labels == undefined){
        res.send({
            error: 'Bad-Request',
            message: 'base64 Image not received, please check your input and resend.'
        })
    } else {
        res.send({
            success: 'success',
            message: 'labels received successfully'
        })
        makeDir();
        setSalesOrderNumber(salesOrderNumber);
        openDirForOrder();
        setImageType(imageType);
        removeMetaData(labels);
        printFiles();
    }
})

function setSalesOrderNumber(orderNumber){
    salesOrderNo = orderNumber;
}

function setImageType(type){
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

function makeDir(){
    fs.mkdir(os.homedir + '/Desktop/Fedex_BC_Labels', (err) =>{
        if(err){
            if (err.errno == -4075){
                console.log(err.message);
            } else {
                console.err(err);
            }
        }
    });
}

function openDirForOrder(){
        fs.mkdir(os.homedir + '/Desktop/Fedex_BC_Labels/' + salesOrderNo, (err) =>{
        if(err){
            if (err.errno == -4075){
                console.log(err.message);
            } else {
                console.err(err);
            }
        }
    });
}

async function removeMetaData(labels) {
    for(var i = 0; i < labels.length; i++){
        const {EncodedLabel} = labels[i];
        EncodedLabel.replace(/^EncodedLabel:\/\w+;base64,/, ''); 
        decodeBase64(EncodedLabel, i);       
    }   
}

async function decodeBase64(base64Data, index){
    var buffer = Buffer.from(base64Data,'base64');
    labelArray.push(buffer);
    saveImage(wasFileAppended, buffer, index);
}

var wasFileAppended = async function(err, ok){
    if (err) throw err;
    ok;
}

async function saveImage(callback, buffer, ind){
   fs.writeFile(os.homedir + '/Desktop/Fedex_BC_Labels/'+ salesOrderNo + '/label' + ind + '.' + iType, buffer, (err) => {
        if(err) {
            console.error('Error: ', err + ' occured with label ' + ind + ' in folder ' + os.homedir + '/Desktop/Fedex_BC_Labels/'+ salesOrderNo);
            callback(err, false);
        } else {
            console.log('label ' + ind + ' saved to folder ' + os.homedir + '/Desktop/Fedex_BC_Labels/'+ salesOrderNo);
            callback(null, true);
        }
    })
}

async function printFiles(){
    var dir;
    fs.opendir(os.homedir + '/Desktop/Fedex_BC_Labels/'+ salesOrderNo,(err, directory) =>{
        if(err){
            console.err(err);
        } else {
            dir = directory;
        }
    });

    

    printer.printDirect()
}


app.listen(PORT, ()=>{
    console.log('Fedex print server running...');
},)