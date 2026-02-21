const { createServer } = require('http');
const { WebSocketServer } = require('ws');
const { connect } = require('net');
const { spawn } = require('child_process');
const crypto = require('crypto');

// 配置本地运行端口和随机生成一个 UUID
const PORT = process.env.PORT || 8080;
const UUID = crypto.randomUUID();

// 1. 创建基础 HTTP 服务
const server = createServer((req, res) => {
    res.writeHead(200);
    res.end('VLESS Node.js Server is running!');
});

// 2. 创建 WebSocket 服务
const wss = new WebSocketServer({ server });

wss.on('connection', (ws) => {
    ws.once('message', (msg) => {
        try {
            // VLESS 协议的极简解析 (基于 XTLS 标准)
            if (msg.length < 24) return ws.close();
            
            const version = msg[0];
            const optLen = msg[17];
            let offset = 18 + optLen;
            
            const cmd = msg[offset]; // 1: TCP
            offset++;
            
            const port = msg.readUInt16BE(offset);
            offset += 2;
            
            const addrType = msg[offset];
            offset++;
            
            let addr = '';
            if (addrType === 1) { // IPv4
                addr = msg.slice(offset, offset + 4).join('.');
                offset += 4;
            } else if (addrType === 2) { // 域名
                const len = msg[offset];
                offset++;
                addr = msg.slice(offset, offset + len).toString('utf-8');
                offset += len;
            } else if (addrType === 3) { // IPv6 (简略处理)
                offset += 16;
                addr = '::1'; 
            }

            const rawData = msg.slice(offset);

            // 如果是 TCP 请求，则建立与目标网站的连接
            if (cmd === 1) {
                const remoteSocket = connect(port, addr, () => {
                    remoteSocket.write(rawData);
                    // 握手成功，返回 VLESS 响应头 [version, 0]
                    ws.send(new Uint8Array([version, 0]));
                });

                // 流量对拷 (Piping)
                remoteSocket.on('data', (data) => ws.send(data));
                remoteSocket.on('error', () => ws.close());
                remoteSocket.on('end', () => ws.close());

                ws.on('message', (data) => remoteSocket.write(data));
                ws.on('close', () => remoteSocket.destroy());
            } else {
                // 不支持 UDP 等其他指令，直接关闭
                ws.close(); 
            }
        } catch (e) {
            ws.close();
        }
    });
});

// 3. 启动本地服务并拉起 Argo Tunnel
server.listen(PORT, () => {
    console.log(`[+] 本地 VLESS WS 服务已启动，监听端口: ${PORT}`);
    console.log(`[+] 当前节点 UUID: ${UUID}`);
    startArgoTunnel();
});

function startArgoTunnel() {
    console.log('[+] 正在拉起 Cloudflare Argo 临时隧道 (初次运行可能需要下载组件)...');
    
    // 使用 npx 临时运行 cloudflared，无需提前全局安装
    const cloudflared = spawn('npx', ['-y', 'cloudflared', 'tunnel', '--url', `http://localhost:${PORT}`]);

    cloudflared.stderr.on('data', (data) => {
        const output = data.toString();
        // 使用正则捕获 Cloudflare 分配的临时域名
        const match = output.match(/https:\/\/[a-zA-Z0-9-]+\.trycloudflare\.com/);
        
        if (match) {
            const domain = match[0].replace('https://', '');
            console.log('\n================================================');
            console.log('✅ 隧道建立成功！');
            console.log('================================================');
            
            // 拼接标准的 VLESS 节点分享链接
            const vlessLink = `vless://${UUID}@${domain}:443?encryption=none&security=tls&sni=${domain}&type=ws&host=${domain}&path=%2F#CF-Argo-Node`;
            
            console.log('\n[你的 VLESS 节点链接]:\n');
            console.log(vlessLink);
            console.log('\n================================================');
            console.log('你可以直接复制上面的链接，导入到 v2rayN, Clash Meta 或 Sing-box 中进行测速。');
        }
    });

    cloudflared.on('close', (code) => {
        console.log(`[-] 隧道已关闭，退出码: ${code}`);
    });
}
