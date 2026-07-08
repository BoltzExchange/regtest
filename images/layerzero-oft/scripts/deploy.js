const fs = require("fs");
const path = require("path");

const { Options } = require("@layerzerolabs/lz-v2-utilities");
const hre = require("hardhat");

const MSG_TYPE_SEND = 1;
const OUTPUT_FILE = "deployment.json";

const readPositiveInteger = (name, fallback) => {
    const rawValue = process.env[name];
    const value = Number(
        rawValue === undefined || rawValue === "" ? fallback : rawValue,
    );

    if (!Number.isSafeInteger(value) || value <= 0) {
        throw new Error(`${name} must be a positive integer`);
    }

    return value;
};

const readTokenAmount = (name, fallback) => {
    const rawValue = process.env[name];
    const value = rawValue === undefined || rawValue === "" ? fallback : rawValue;

    return hre.ethers.utils.parseUnits(value, 18);
};

const config = {
    sourceEid: readPositiveInteger("LAYERZERO_OFT_SOURCE_EID", 40231),
    destinationEid: readPositiveInteger("LAYERZERO_OFT_DESTINATION_EID", 40232),
    outputDir: process.env.LAYERZERO_OFT_OUTPUT_DIR || "/data/layerzero-oft",
    initialBalance: readTokenAmount("LAYERZERO_OFT_INITIAL_BALANCE", "1000"),
    lzReceiveGas: readPositiveInteger("LAYERZERO_OFT_LZ_RECEIVE_GAS", 65000),
};

if (config.sourceEid === config.destinationEid) {
    throw new Error("source and destination EIDs must be different");
}

const outputPath = path.join(config.outputDir, OUTPUT_FILE);
const temporaryOutputPath = `${outputPath}.tmp`;

const wait = async (txPromise) => {
    const tx = await txPromise;
    return tx.wait();
};

const toBytes32Address = (address) =>
    hre.ethers.utils.hexZeroPad(hre.ethers.utils.getAddress(address), 32);

async function deployEndpoint(deployer, eid) {
    const factory = await hre.ethers.getContractFactory(
        "EndpointV2Mock",
        deployer,
    );
    const endpoint = await factory.deploy(eid);
    await endpoint.deployed();
    return endpoint;
}

async function deployOft(endpoint, deployer, suffix) {
    const factory = await hre.ethers.getContractFactory("RegtestOFT", deployer);
    const oft = await factory.deploy(
        `Regtest USDT0 ${suffix}`,
        "USDT0",
        endpoint.address,
        deployer.address,
    );
    await oft.deployed();
    return oft;
}

async function deploySide(deployer, name, eid) {
    const endpoint = await deployEndpoint(deployer, eid);
    const oft = await deployOft(endpoint, deployer, name);

    return {
        eid,
        endpoint,
        oft,
    };
}

async function connectRoute(from, to, options) {
    await wait(
        from.endpoint.setDestLzEndpoint(to.oft.address, to.endpoint.address),
    );
    await wait(from.oft.setPeer(to.eid, toBytes32Address(to.oft.address)));
    await wait(
        from.oft.setEnforcedOptions([
            {
                eid: to.eid,
                msgType: MSG_TYPE_SEND,
                options,
            },
        ]),
    );
}

async function writeDeploymentFile(deployment) {
    fs.mkdirSync(config.outputDir, { recursive: true });
    fs.writeFileSync(
        temporaryOutputPath,
        `${JSON.stringify(deployment, null, 2)}\n`,
    );
    fs.renameSync(temporaryOutputPath, outputPath);
}

function removeStaleDeploymentFile() {
    fs.rmSync(outputPath, { force: true });
    fs.rmSync(temporaryOutputPath, { force: true });
}

function deploymentJson({
    network,
    deployerAddress,
    source,
    destination,
    options,
}) {
    return {
        network: {
            name: network.name,
            chainId: network.chainId,
        },
        deployer: deployerAddress,
        eids: {
            source: source.eid,
            destination: destination.eid,
        },
        endpoints: {
            source: source.endpoint.address,
            destination: destination.endpoint.address,
        },
        oft: {
            source: source.oft.address,
            destination: destination.oft.address,
        },
        enforcedOptions: {
            msgTypeSend: MSG_TYPE_SEND,
            lzReceiveGas: config.lzReceiveGas,
            options,
        },
    };
}

async function main() {
    const [deployer] = await hre.ethers.getSigners();

    removeStaleDeploymentFile();

    const source = await deploySide(deployer, "Source", config.sourceEid);
    const destination = await deploySide(
        deployer,
        "Destination",
        config.destinationEid,
    );

    const lzReceiveOptions = Options.newOptions()
        .addExecutorLzReceiveOption(config.lzReceiveGas, 0)
        .toHex();

    await connectRoute(source, destination, lzReceiveOptions);
    await connectRoute(destination, source, lzReceiveOptions);
    await wait(source.oft.mint(deployer.address, config.initialBalance));

    const deployment = deploymentJson({
        network: await hre.ethers.provider.getNetwork(),
        deployerAddress: deployer.address,
        source,
        destination,
        options: lzReceiveOptions,
    });

    await writeDeploymentFile(deployment);
    console.log(JSON.stringify(deployment, null, 2));
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
