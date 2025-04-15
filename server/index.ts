import { randomUUIDv7, type Server, type ServerWebSocket } from 'bun';
import { YouTube } from 'youtube-sr';
import fs from 'node:fs';
import path from 'node:path';
import YTDlpWrap from 'yt-dlp-wrap';

// --- Configuration ---
const FILES_DIR_NAME = 'files';
const FILES_DIR = path.join(process.cwd(), FILES_DIR_NAME);
const THUMBNAIL_EXTENSION = 'jpg'; // Choose jpg or webp, jpg is more common

const YT_DLP_PATH = path.join(process.cwd(), 'local-yt-dlp');
if (!fs.existsSync(YT_DLP_PATH))
    await YTDlpWrap.downloadFromGithub(YT_DLP_PATH);
const ytDlpWrap = new YTDlpWrap();
ytDlpWrap.setBinaryPath(YT_DLP_PATH);

if (YTDlpWrap)
    if (!fs.existsSync(FILES_DIR)) {
        //await YTDlpWrap.downloadFromGithub('./yt-dlp/binary');

        // --- Ensure files directory exists ---
        console.log(`Creating directory: ${FILES_DIR}`);
        fs.mkdirSync(FILES_DIR, { recursive: true });
    }

// --- Types (Existing + New) ---
type ClientType = 'user' | 'robot';

type FromHostMessageType =
    | 'host_listUsers'
    | 'host_pairConnect'
    | 'host_pairDisconnect';
type FromUserMessageType = 'user_pairConnect' | 'user_pairDisconnect';
type BetweenClientsMessageType = 'client_message';
interface SocketMessage {
    type: FromHostMessageType | FromUserMessageType | BetweenClientsMessageType;
    data: any;
}

type WebSocketData = {
    id: string;
    createdAt: number;
    clientType: ClientType;
    pairedWith?: ServerWebSocket<WebSocketData>;
};

// --- WebSocket State (Existing) ---
const allClients = new Map<string, ServerWebSocket<WebSocketData>>();
const CHANNEL_AVAILABLE_CLIENTS = 'available-clients';

// --- Helper Functions ---

// Sanitizes a string to be used as a filename
function sanitizeFilename(name: string): string {
    // Remove invalid characters, replace spaces with underscores
    return name
        .replace(/[\/\\?%*:|"<>]/g, '') // Remove potentially problematic chars
        .replace(/\s+/g, '_') // Replace whitespace with underscores
        .substring(0, 100); // Limit length
}

// --- Construct Public URL Helper ---
function getPublicUrl(req: Request, server: Server, filename: string): string {
    const fileUrlPath = `/${FILES_DIR_NAME}/${encodeURIComponent(filename)}`;
    const host = req.headers.get('host') || `${server.hostname}:${server.port}`;
    const forwardedProto = req.headers.get('x-forwarded-proto'); // Check for proxy header
    const scheme =
        forwardedProto === 'https'
            ? 'https'
            : server.hostname === 'localhost' || server.hostname === '127.0.0.1'
            ? 'http'
            : 'https'; // Default based on host or assume https
    return `${scheme}://${host}${fileUrlPath}`;
}

// Downloads a YouTube video as MP3 using yt-dlp
async function downloadAudio(
    videoUrl: string,
    outputFilename: string
): Promise<{ success: boolean; error?: string; filePath?: string }> {
    const outputPath = path.join(FILES_DIR, outputFilename);
    const outputTemplate = path.join(FILES_DIR, '%(title)s.%(ext)s'); // Let yt-dlp handle sanitization better if needed

    console.log(`Attempting to download: ${videoUrl} to ${outputPath}`);

    // Use a generic output template first to let yt-dlp determine the actual final name based on metadata
    // We'll figure out the exact name later if needed, or just use the sanitized one for the URL
    const outputTemplateForYtdlp = path.join(
        FILES_DIR,
        `${outputFilename}.%(ext)s`
    );

    const args = [
        '-x', // Extract audio
        '--audio-format',
        'mp3',
        '--audio-quality', // Select reasonable quality
        '5', // 0 (best) to 10 (worst), 5 is default VBR
        '-o',
        outputTemplateForYtdlp, // Output template
        videoUrl,
        // Optional: Add sponsorblock skipping
        // '--sponsorblock-remove', 'all',
        // '--no-warnings', // Suppress yt-dlp warnings if desired
    ];

    const proc = Bun.spawn([YT_DLP_PATH, ...args], {
        stdout: 'pipe', // Capture stdout
        stderr: 'pipe', // Capture stderr
    });

    const exitCode = await proc.exited;
    const stdout = await new Response(proc.stdout).text();
    const stderr = await new Response(proc.stderr).text();

    // yt-dlp might output useful info to stdout even on success
    // console.log("yt-dlp stdout:", stdout);

    if (exitCode !== 0) {
        console.error(`yt-dlp failed for ${videoUrl} (code ${exitCode}):`);
        console.error('yt-dlp stderr:', stderr);
        console.error('yt-dlp stdout:', stdout); // Log stdout too, might contain info
        return {
            success: false,
            error: `yt-dlp failed: ${
                stderr || stdout || `Exit code ${exitCode}`
            }`,
        };
    }

    // yt-dlp might rename the file based on the title, find the actual file
    const potentialFinalPath = path.join(FILES_DIR, `${outputFilename}.mp3`);
    if (await Bun.file(potentialFinalPath).exists()) {
        console.log(`Download successful: ${potentialFinalPath}`);
        return { success: true, filePath: potentialFinalPath };
    } else {
        // This part is tricky if yt-dlp uses a different sanitized title.
        // A more robust way would be to parse yt-dlp's output or list the dir
        // For now, assume it used the provided filename base.
        console.warn(
            `Could not confirm exact output file path for: ${outputFilename}.mp3`
        );
        return { success: true, filePath: potentialFinalPath }; // Assume success but path might be slightly off
    }
}

async function downloadThumbnail(
    thumbnailUrl: string,
    outputFilePath: string // Full path including extension
): Promise<{ success: boolean; error?: string }> {
    console.log(
        `Attempting to download thumbnail: ${thumbnailUrl} to ${outputFilePath}`
    );
    try {
        const response = await fetch(thumbnailUrl);
        if (!response.ok) {
            throw new Error(
                `Failed to fetch thumbnail: ${response.status} ${response.statusText}`
            );
        }
        const imageBuffer = await response.arrayBuffer();
        await Bun.write(outputFilePath, imageBuffer);
        console.log(`Thumbnail download successful: ${outputFilePath}`);
        return { success: true };
    } catch (error: any) {
        console.error(`Error downloading thumbnail ${thumbnailUrl}:`, error);
        return { success: false, error: error.message };
    }
}

// --- WebSocket Logic (Existing) ---
const publishAvailableClients = (ws: ServerWebSocket<WebSocketData>) => {
    // ... (keep existing implementation)
    const message: SocketMessage = {
        type: 'host_listUsers',
        data: Array.from(
            allClients
                .values()
                .filter(({ data: { pairedWith } }) => !Boolean(pairedWith))
                .map(({ data: { id, createdAt, clientType } }) => ({
                    id,
                    createdAt,
                    clientType,
                }))
        ),
    };

    ws.publish(CHANNEL_AVAILABLE_CLIENTS, JSON.stringify(message));
};

// --- Bun Server ---
const server = Bun.serve<WebSocketData>({
    idleTimeout: 60,
    async fetch(req, server) {
        const url = new URL(req.url);
        const pathname = url.pathname;
        const method = req.method;

        try {
            // Add a try-catch block for better error handling in fetch
            // --- REST API Routes ---

            // Route: /request-song?query=...
            if (pathname === '/request-song' && method === 'GET') {
                const query = url.searchParams.get('query');
                if (!query) {
                    return new Response(
                        JSON.stringify({
                            error: 'Query parameter is required',
                        }),
                        {
                            status: 400,
                            headers: { 'Content-Type': 'application/json' },
                        }
                    );
                }

                console.log(`Received song request for query: "${query}"`);

                try {
                    // Search YouTube
                    // Adding "music" or "song" might help prioritize actual songs
                    let searchResults = (
                        await YouTube.search(query + ' music', {
                            limit: 8, // Look through top 5 results
                            type: 'video',
                        })
                    ).filter(
                        (result) =>
                            result.title &&
                            !result.title
                                .toLowerCase()
                                .includes('official video') &&
                            !result.title.toLowerCase().includes('music video')
                    );

                    if (!searchResults || searchResults.length === 0) {
                        return new Response(
                            JSON.stringify({
                                error: 'No YouTube results found',
                            }),
                            {
                                status: 404,
                                headers: { 'Content-Type': 'application/json' },
                            }
                        );
                    }

                    const topResult = searchResults[0];
                    if (
                        !topResult ||
                        !topResult.id ||
                        !topResult.url ||
                        !topResult.title
                    ) {
                        return new Response(
                            JSON.stringify({
                                error: 'Found result is invalid',
                            }),
                            {
                                status: 500,
                                headers: { 'Content-Type': 'application/json' },
                            }
                        );
                    }

                    // Get thumbnail URL (prefer 'high' quality if available)
                    const thumbnailUrl = topResult.thumbnail?.url; // youtube-sr might change structure, check object
                    if (!thumbnailUrl) {
                        console.warn(
                            `No thumbnail URL found for video: ${topResult.title} (${topResult.id})`
                        );
                        // Decide if this is a fatal error or just proceed without thumbnail
                        // For now, we'll proceed but won't have a thumbnail URL in response
                    }
                    console.log(
                        `Found video: "${topResult.title}" (${topResult.id})`
                    );

                    // Generate filename (simple sanitization)
                    const baseFilename = sanitizeFilename(topResult.title);
                    const audioFilename = `${baseFilename}.mp3`;
                    const thumbnailFilename = `${baseFilename}.${THUMBNAIL_EXTENSION}`;

                    const localAudioPath = path.join(FILES_DIR, audioFilename);
                    const localThumbnailPath = path.join(
                        FILES_DIR,
                        thumbnailFilename
                    );

                    const publicAudioUrl = getPublicUrl(
                        req,
                        server,
                        audioFilename
                    );
                    const publicThumbnailUrl = thumbnailUrl
                        ? getPublicUrl(req, server, thumbnailFilename)
                        : null; // Only if we have a thumbnail URL

                    const audioExists = await Bun.file(localAudioPath).exists();
                    // Check existence based on *expected* path, even if yt-dlp named it slightly differently before
                    const thumbnailExists = thumbnailUrl
                        ? await Bun.file(localThumbnailPath).exists()
                        : false;

                    if (audioExists && thumbnailExists) {
                        console.log(
                            `Audio and thumbnail already exist for: ${baseFilename}`
                        );
                        return new Response(
                            JSON.stringify({
                                message:
                                    'Song and thumbnail already downloaded',
                                title: topResult.title,
                                url: publicAudioUrl,
                                thumbnailUrl: publicThumbnailUrl,
                            }),
                            { headers: { 'Content-Type': 'application/json' } }
                        );
                    }
                    if (audioExists && !thumbnailExists && thumbnailUrl) {
                        console.log(
                            `Audio exists, attempting to download missing thumbnail for: ${baseFilename}`
                        );
                        // Download only the missing thumbnail
                        const thumbDownloadResult = await downloadThumbnail(
                            thumbnailUrl,
                            localThumbnailPath
                        );
                        if (!thumbDownloadResult.success) {
                            console.warn(
                                `Failed to download missing thumbnail: ${thumbDownloadResult.error}`
                            );
                            // Respond anyway, just without the thumbnail URL this time
                        }
                        return new Response(
                            JSON.stringify({
                                message:
                                    'Song already downloaded, fetched thumbnail',
                                title: topResult.title,
                                url: publicAudioUrl,
                                thumbnailUrl: thumbDownloadResult.success
                                    ? publicThumbnailUrl
                                    : null, // Only include if successful
                            }),
                            { headers: { 'Content-Type': 'application/json' } }
                        );
                    }

                    // --- Download Audio ---
                    let actualAudioPath = localAudioPath; // Assume standard path initially
                    if (!audioExists) {
                        console.log(`Downloading audio for: ${baseFilename}`);
                        const audioDownloadResult = await downloadAudio(
                            topResult.url,
                            baseFilename
                        ); // Pass base filename
                        if (
                            !audioDownloadResult.success ||
                            !audioDownloadResult.filePath
                        ) {
                            return new Response(
                                JSON.stringify({
                                    error: 'Failed to download song audio',
                                    details: audioDownloadResult.error,
                                }),
                                {
                                    status: 500,
                                    headers: {
                                        'Content-Type': 'application/json',
                                    },
                                }
                            );
                        }
                        // Update actual path if yt-dlp provided a different one (e.g., from fallback search)
                        actualAudioPath = audioDownloadResult.filePath;
                    } else {
                        console.log(`Audio already exists: ${actualAudioPath}`);
                    }

                    // Re-check existence after download attempt, using the path yt-dlp *should* have created
                    // Note: If yt-dlp sanitizes differently, this might still fail.
                    const finalFilePath = actualAudioPath; // Use path from download result if available
                    if (!(await Bun.file(finalFilePath).exists())) {
                        console.error(
                            `Download reported success, but file not found at ${finalFilePath}`
                        );
                        return new Response(
                            JSON.stringify({
                                error: 'Download finished but file not found on server.',
                            }),
                            {
                                status: 500,
                                headers: { 'Content-Type': 'application/json' },
                            }
                        );
                    }

                    // --- Download Thumbnail ---
                    let finalPublicThumbnailUrl = null;
                    if (!thumbnailExists && thumbnailUrl) {
                        console.log(
                            `Downloading thumbnail for: ${baseFilename}`
                        );
                        const thumbDownloadResult = await downloadThumbnail(
                            thumbnailUrl,
                            localThumbnailPath
                        );
                        if (thumbDownloadResult.success) {
                            finalPublicThumbnailUrl = publicThumbnailUrl; // Use the pre-calculated public URL
                        } else {
                            console.warn(
                                `Failed to download thumbnail: ${thumbDownloadResult.error}`
                            );
                            // Proceed without thumbnail if download fails
                        }
                    } else if (thumbnailExists) {
                        console.log(
                            `Thumbnail already exists: ${localThumbnailPath}`
                        );
                        finalPublicThumbnailUrl = publicThumbnailUrl; // Use existing
                    }

                    // --- Final Check & Response ---
                    // Check audio existence again using the actual path determined
                    if (!(await Bun.file(actualAudioPath).exists())) {
                        console.error(
                            `Audio download reported success, but file not found at ${actualAudioPath}`
                        );
                        return new Response(
                            JSON.stringify({
                                error: 'Audio download finished but file not found on server.',
                            }),
                            {
                                status: 500,
                                headers: { 'Content-Type': 'application/json' },
                            }
                        );
                    }

                    return new Response(
                        JSON.stringify({
                            message: 'Song processed successfully',
                            title: topResult.title,
                            url: publicAudioUrl, // Always use the URL derived from sanitized name for consistency
                            thumbnailUrl: finalPublicThumbnailUrl, // Will be null if thumbnail failed or didn't exist
                        }),
                        { headers: { 'Content-Type': 'application/json' } }
                    );
                } catch (error: any) {
                    console.error('Error processing song request:', error);
                    return new Response(
                        JSON.stringify({
                            error: 'Internal server error during song request',
                            details: error.message,
                        }),
                        {
                            status: 500,
                            headers: { 'Content-Type': 'application/json' },
                        }
                    );
                }
            }

            // Route: /songs - List available MP3s
            else if (pathname === '/songs' && method === 'GET') {
                try {
                    const files = await fs.promises.readdir(FILES_DIR);
                    const mp3Files = files.filter((file) =>
                        file.toLowerCase().endsWith('.mp3')
                    );
                    const songsWithUrls = mp3Files.map((filename) => {
                        const fileUrlPath = `/${FILES_DIR_NAME}/${encodeURIComponent(
                            filename
                        )}`;
                        const host =
                            req.headers.get('host') ||
                            `${server.hostname}:${server.port}`;
                        const scheme =
                            server.hostname === 'localhost' ||
                            server.hostname === '127.0.0.1'
                                ? 'http'
                                : 'https';
                        const publicFileUrl = `${scheme}://${host}${fileUrlPath}`;
                        return {
                            filename: filename,
                            url: publicFileUrl,
                        };
                    });

                    return new Response(JSON.stringify(songsWithUrls), {
                        headers: { 'Content-Type': 'application/json' },
                    });
                } catch (error: any) {
                    // Handle case where directory might not exist (though we create it)
                    if (error.code === 'ENOENT') {
                        return new Response(JSON.stringify([]), {
                            // Return empty list if dir doesn't exist
                            headers: { 'Content-Type': 'application/json' },
                        });
                    }
                    console.error('Error listing songs:', error);
                    return new Response(
                        JSON.stringify({
                            error: 'Internal server error listing songs',
                            details: error.message,
                        }),
                        {
                            status: 500,
                            headers: { 'Content-Type': 'application/json' },
                        }
                    );
                }
            }

            // Route: /files/* - Serve downloaded MP3s
            else if (
                pathname.startsWith(`/${FILES_DIR_NAME}/`) &&
                method === 'GET'
            ) {
                // Extract filename, decode URI component potentially added by the client/browser
                const requestedFilename = decodeURIComponent(
                    pathname.substring(`/${FILES_DIR_NAME}/`.length)
                );

                // Basic security: prevent path traversal
                if (
                    requestedFilename.includes('..') ||
                    requestedFilename.includes('/')
                ) {
                    return new Response('Invalid filename', { status: 400 });
                }

                const filePath = path.join(FILES_DIR, requestedFilename);

                try {
                    const file = Bun.file(filePath);
                    if (await file.exists()) {
                        console.log(`Serving file: ${filePath}`);
                        // Bun automatically handles Content-Type for known extensions like .mp3
                        // and supports range requests for seeking.
                        return new Response(file);
                    } else {
                        console.log(`File not found: ${filePath}`);
                        return new Response('File not found', { status: 404 });
                    }
                } catch (error) {
                    console.error(`Error serving file ${filePath}:`, error);
                    return new Response('Internal server error', {
                        status: 500,
                    });
                }
            }

            // --- WebSocket Upgrade Route (Existing) ---
            else if (pathname === '/ws') {
                // ... (keep existing WebSocket upgrade logic)
                if (
                    server.upgrade(req, {
                        data: {
                            id: randomUUIDv7(),
                            createdAt: Date.now(),
                            clientType: url.searchParams.get(
                                'clientType'
                            ) as ClientType,
                        },
                    })
                )
                    return; // Bun handles the response internally on upgrade

                return new Response('Upgrade failed', { status: 500 });
            }

            // --- Basic Root Route (Existing) ---
            else if (pathname === '/' && method === 'GET') {
                return new Response('Hello World!');
            }

            // --- Fallback 404 ---
            else {
                return new Response('Not Found', { status: 404 });
            }
        } catch (error) {
            console.error('Unhandled error in fetch handler:', error);
            return new Response('Internal Server Error', { status: 500 });
        }
    },
    websocket: {
        // --- Keep ALL existing WebSocket handlers (open, close, message) ---
        open(ws) {
            console.log('WebSocket opened', ws.data);

            allClients.set(ws.data.id, ws);
            if (ws.data.clientType === 'user')
                ws.subscribe(CHANNEL_AVAILABLE_CLIENTS);

            publishAvailableClients(ws);
        },
        close(ws, code, message) {
            // Added params for potential debugging
            console.log(
                `WebSocket closed (Code: ${code}, Message: ${message})`,
                ws.data
            );

            allClients.delete(ws.data.id);
            // Disconnect logic
            if (ws.data.pairedWith) {
                const otherClient = ws.data.pairedWith;
                const disconnectMessage: SocketMessage = {
                    type: 'host_pairDisconnect',
                    data: 'Partner disconnected',
                };
                // Check if the other client is still connected before sending
                if (allClients.has(otherClient.data.id)) {
                    otherClient.send(JSON.stringify(disconnectMessage));
                    otherClient.data.pairedWith = undefined; // Clear pairing on the other side too
                }
                ws.data.pairedWith = undefined; // Clear pairing on this side
                publishAvailableClients(ws); // Update list for everyone
            } else {
                // If the closing client was not paired, still publish updates
                // (especially if it was a 'robot' potentially available for pairing)
                publishAvailableClients(ws);
            }
        },
        message(ws, event) {
            try {
                // Add try-catch for message parsing
                const message: SocketMessage = JSON.parse(event.toString());
                console.log(
                    `Received message from ${ws.data.id}:`,
                    message.type,
                    message.data
                ); // Log received messages

                if (ws.data.pairedWith) {
                    const otherClient = ws.data.pairedWith;
                    // Check if the paired client is still connected before processing/forwarding
                    if (!allClients.has(otherClient.data.id)) {
                        console.warn(
                            `Client ${ws.data.id} tried to send message, but partner ${otherClient.data.id} is disconnected.`
                        );
                        // Optionally inform the sender their partner is gone
                        const partnerGoneMessage: SocketMessage = {
                            type: 'host_pairDisconnect',
                            data: 'Partner disconnected',
                        };
                        ws.send(JSON.stringify(partnerGoneMessage));
                        ws.data.pairedWith = undefined; // Clear pairing
                        publishAvailableClients(ws);
                        return; // Stop processing this message
                    }

                    switch (message.type) {
                        case 'user_pairDisconnect':
                            console.log(
                                `User ${ws.data.id} requested disconnect from ${otherClient.data.id}`
                            );
                            const disconnectMsg: SocketMessage = {
                                type: 'host_pairDisconnect',
                                data: `Disconnected by partner (${ws.data.id})`,
                            };
                            // Send to both clients confirming disconnect
                            ws.send(JSON.stringify(disconnectMsg));
                            otherClient.send(JSON.stringify(disconnectMsg));

                            // Clear pairing state on both sides
                            ws.data.pairedWith = undefined;
                            otherClient.data.pairedWith = undefined;

                            publishAvailableClients(ws); // Update available clients list
                            break;

                        default:
                            // Forward other messages directly between paired clients
                            const forwardMessage: SocketMessage = {
                                type: 'client_message', // Keep type generic for client interpretation
                                data: message, // Forward the original parsed message object
                            };
                            otherClient.send(JSON.stringify(forwardMessage));
                            console.log(
                                `Forwarded message from ${ws.data.id} to ${otherClient.data.id}`
                            );
                            break; // Use break instead of return here
                    }
                } else {
                    // Logic for unpaired clients
                    if (ws.data.clientType === 'user') {
                        switch (message.type) {
                            case 'user_pairConnect':
                                const robotID = message.data as string;
                                console.log(
                                    `User ${ws.data.id} requests pairing with robot ${robotID}`
                                );
                                const robot = allClients.get(robotID); // More efficient lookup

                                if (
                                    robot &&
                                    robot.data.clientType === 'robot' &&
                                    !robot.data.pairedWith
                                ) {
                                    console.log(
                                        `Pairing user ${ws.data.id} with robot ${robotID}`
                                    );
                                    ws.data.pairedWith = robot;
                                    robot.data.pairedWith = ws;

                                    const connectMsg: SocketMessage = {
                                        type: 'host_pairConnect',
                                        data: {
                                            userId: ws.data.id,
                                            robotId: robot.data.id,
                                        }, // Send both IDs
                                    };
                                    ws.send(JSON.stringify(connectMsg));
                                    robot.send(JSON.stringify(connectMsg));

                                    publishAvailableClients(ws); // Update list (robot is no longer available)
                                } else {
                                    console.log(
                                        `Pairing failed: Robot ${robotID} not found, not a robot, or already paired.`
                                    );
                                    // Optionally send a failure message back to the user
                                    ws.send(
                                        JSON.stringify({
                                            type: 'host_pairError',
                                            data: 'Robot not available for pairing',
                                        })
                                    );
                                }
                                break;
                            default:
                                console.warn(
                                    `Unpaired user ${ws.data.id} sent unhandled message type: ${message.type}`
                                );
                                // Optionally send an error message back
                                ws.send(
                                    JSON.stringify({
                                        type: 'host_error',
                                        data: `Invalid message type '${message.type}' when unpaired`,
                                    })
                                );
                                break; // Use break instead of return
                        }
                    } else {
                        // Handle messages from unpaired robots if necessary
                        console.warn(
                            `Unpaired robot ${ws.data.id} sent message type: ${message.type} - Ignoring.`
                        );
                    }
                }
            } catch (error) {
                console.error(
                    `Failed to process message from ${ws.data.id}:`,
                    error
                );
                // Attempt to send an error back to the client if the connection is open
                if (ws.readyState === WebSocket.OPEN) {
                    try {
                        ws.send(
                            JSON.stringify({
                                type: 'host_error',
                                data: 'Failed to process message (invalid JSON?)',
                            })
                        );
                    } catch (sendError) {
                        console.error(
                            `Failed to send error message back to client ${ws.data.id}:`,
                            sendError
                        );
                    }
                }
            }
        }, // <--- Added closing brace
    },
    error(error: Error) {
        // Add top-level error handler
        console.error('Bun server error:', error);
        return new Response('Internal Server Error', { status: 500 });
    },
});

console.log(`Listening on ${server.url}`);
// Add base URL for file serving reference
console.log(`Serving files from: ${server.url}${FILES_DIR_NAME}/`);
