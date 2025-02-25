function writeContrastMaps()

    %set(0, 'DefaultFigureVisible', 'off');
    set(groot, 'DefaultAxesFontName', 'Lucida Bright'); % For axes labels and ticks
    set(groot, 'DefaultTextFontName', 'Lucida Bright'); % For general text objects
    set(groot, 'DefaultUicontrolFontName', 'Lucida Bright'); % For UI elements
    
    % Convert gifti files to mgz files (PUT BACK LATER)
    projectDir = getenv('BIDS_DIR');
    subject = ['sub-',getenv('SUBJECT_ID')];
    session = ['ses-',getenv('SESSION_ID')];
    protocol = getenv('PROTOCOL'); 
    codeDir = getenv('CODE_DIR'); 
    
%     % REMOVE LATER
%     projectDir = '/Users/rje257/Desktop/transfer_gate/NEI_BIDS/';
%     %projectDir = setup_user('rania', projectDir)
%     subject = 'sub-wlsubj127';
%     session = 'ses-nyu3t02';
%     protocol = 'mloc'; %'mloc';
%     codeDir = '/Users/rje257/Documents/GitHub/NEI_fitGLM';
%     setenv('SUBJECTS_DIR', fullfile(projectDir, 'derivatives', 'freesurfer'));
    
    % Load JSON file (which contains labels per condition, and list of desired
    % contrasts
    jsonFile = fullfile(codeDir, 'localizers_params.json');
    fid = fopen(jsonFile, 'r');
    raw = fread(fid, inf);
    fclose(fid);
    jsonData = jsondecode(char(raw'));  % Convert JSON to MATLAB struct
    
    taskBidsName = jsonData.protocols.(protocol).bids_task_name;
    subjectDir = fullfile(projectDir, 'derivatives','freesurfer');
    
    % Extract label_description for protocol
    labels = jsonData.protocols.(protocol).label_description;
    
    conditionLabelInt = str2double({labels.value});
    conditionLabelStr = {labels.shortName};
    conditionLabelmap = containers.Map(conditionLabelInt, conditionLabelStr);
    
    %% combine trials for each condition to generate separate maps for each beta
    
    % folder with GLMsingle output
    derSubfolder = sprintf('%s/derivatives/GLMsingle/%s/%s/%s', projectDir, subject, session, taskBidsName);
    
    % load in results from GLMsingle
    fname = sprintf('%s_%s_%s_results.mat', subject, session, []);
    load(fullfile(derSubfolder, fname), 'results', 'resultsdesign');
    
    designConds = sort(unique(resultsdesign.stimorder));
    nBetas = length(designConds);
    
    % check that each condition in design matrix is in JSON dict
    if ~isequal(designConds, sort(conditionLabelInt))
        error('%s does not contain labels for one or more integers in design matrix', jsonFile);
    end
    
    % 4th element of results is the full GLMsingle output (type D - with GMLdenoise and ridge reg)
    [~, nvert, ~, ntrials] = size(results{4}.modelmd);
    
    if nvert<=1
        [nvert, ~, ~, ntrials] = size(results{4}.modelmd);
    end
    
    % average betas across trials if I ran glmSingle
    betamaps = nan(nvert, nBetas); % conditions
    
    for ci=1:nBetas
    
        % convert to int used in JSON (safety in case not 1,2,3 etc)
        designLabel = designConds(ci);
        condSelect = resultsdesign.stimorder==designLabel;
    
        betas = results{4}.modelmd(:,:,:,condSelect); % 4th element is output for complete GLMsingle
        newbetas = squeeze(betas);
        
        % condition mean across trials
        betamaps(:,ci) = mean(newbetas,2);
    end
    
    %% save each beta surface map as mgz
    
    for bi=1:nBetas
        writeMGZ(projectDir, subject, betamaps(:,bi), fullfile(derSubfolder, 'betas'), sprintf('beta%i_%s', bi, conditionLabelmap(bi)))
    end
    
    %% save each contrst surface map as mgz
    
    % compute the contrasts (based on what is listed in the JSON file)
    contrasts = jsonData.protocols.(protocol).contrasts;
    
    % Loop through each contrast
    for i = 1:length(contrasts)
        name = contrasts(i).name;
        positive = contrasts(i).positive;
        negative = contrasts(i).negative;
        
        pos = mean(betamaps(:,positive),2); % dim 2 contains subconditions after indexing positive
        neg = mean(betamaps(:,negative),2); % or negative
    
        betaVal = pos-neg;
        writeMGZ(projectDir, subject, betaVal, fullfile(derSubfolder, 'contrasts'), name)
    
    end
    
    %% take snapshots of each contrast map and save as pngs
    
    overlayNames = {contrasts.name};
    views = {'lateral', 'inferior', 'posterior'};
    
    % Create a custom colormap for curv
    n = 256;  % Number of colors in the colormap (you can adjust this number)
    light_gray = 0.25;  % Light gray value
    dark_gray = 0.75;   % Dark gray value
    gray_values = linspace(light_gray, dark_gray, n);
    curv_colormap = [gray_values(:), gray_values(:), gray_values(:)];
    
    % Define the colormap
    gray1 = [0.8, 0.8, 0.8];  % Light gray (for 0-0.25)
    gray2 = [0.3, 0.3, 0.3];  % Dark gray (for 0.25-0.5)
    jetColors = jet(256);      % Get the jet colormap (for 0.5 to 1.5)
    
    % Create the custom colormap by concatenating sections
    nGray1 = 64;  % Light gray (0 to 0.25)
    nGray2 = 64;  % Dark gray (0.25 to 0.5)
    nJet = 256;   % Full JET colormap range (0.5 to 1.5)
    gray1 = [0.8, 0.8, 0.8]; % Light gray
    gray2 = [0.3, 0.3, 0.3]; % Dark gray
    gray1Range = repmat(gray1, nGray1, 1);
    gray2Range = repmat(gray2, nGray2, 1);
    jetColors = jet(nJet); 
    jetRange = jetColors; % Use full jet range
    custom_jet = [gray1Range; gray2Range; jetRange];
    
    min_thresh = 0.5;
    max_thresh = 1.5;
    hemis = {'lh', 'rh'};
    
    
    for oi=1:numel(overlayNames)
        overlayName = overlayNames{oi};
        f1 = figure('Visible', 'off', 'Position', [1748 296 793 1005]);
        f = figure('Visible', 'off', 'Position', [1748 296 793 1005]);
        try
            set(f, 'Renderer', 'opengl'); % will print cleaner graphic
        catch
            set(f, 'Renderer', 'zbuffer');
        end
        disp(get(f, 'Renderer'))
        counter=1;
    
        for vi=1:numel(views)
    
            viewPoint = views{vi};
    
            for hemi=1:numel(hemis)
            
                hemiName = hemis{hemi};
            
                % load inflated surface
                inflated = fullfile(subjectDir, subject, 'surf', sprintf('%s.inflated', hemiName));  % hemisphere inflated surface
                [vertices, faces] = read_surf(inflated);
                faces=faces+1;
            
                % load curv file
                curv_file = fullfile(subjectDir, subject,'surf', sprintf('%s.curv', hemiName));  % Replace with your curvature file path
                curv_data = read_curv(curv_file);  % Load the curvature data (vertex-wise)
                curv_midpoints = linspace(0,min_thresh, 4); % this is just a hack to display display binary curv values without interfering with overlay thresh
                curv_data(curv_data > 0) = curv_midpoints(3);
                curv_data(curv_data < 0) = curv_midpoints(2);
            
                figure(f1)
                subplot(numel(overlayNames),2,counter)
                h1 = trisurf(faces, vertices(:,1), vertices(:,2), vertices(:,3), ...
                        curv_data, 'FaceColor', 'flat', 'EdgeColor', 'none');
                colormap(curv_colormap);
                caxis([curv_midpoints(1), curv_midpoints(4)]); 
                axis equal;
                grid off;
                axis off;
                set(gca, 'XTick', [], 'YTick', [], 'ZTick', [])
                hold on
                
                mgz_file = fullfile(derSubfolder, 'contrasts', sprintf('%s.%s.mgz', hemiName, overlayName));  
                mgz = MRIread(mgz_file);
                
                thresholded_data = mgz.vol;  % Get the MGZ data
                thresholded_data(thresholded_data < min_thresh) = curv_data(thresholded_data < min_thresh);
                thresholded_data(thresholded_data > max_thresh) = max_thresh;
                
                validIdx = ~isnan(thresholded_data);
                faces_valid = faces(all(validIdx(faces), 2), :);
                vertices_valid = vertices(validIdx, :);
                thresholded_data_valid = thresholded_data(validIdx);
            
                % Plot the left hemisphere surface using trisurf (for faces)
                 h2 = trisurf(faces, vertices(:,1), vertices(:,2), vertices(:,3), ...
                        thresholded_data, 'FaceColor', 'flat', 'EdgeColor', 'none');
                caxis([curv_midpoints(1), max_thresh]); 
                colormap(custom_jet);
                axis equal;
                axis off;
                grid off;
                lighting none; 
                box off;
                set(gca, 'XTick', [], 'YTick', [], 'ZTick', [])
                set(gca, 'DataAspectRatioMode', 'manual');
                if strcmp(hemiName, 'lh')
                    if strcmp(viewPoint, 'lateral')
                        savedView = [-90,0];
                        view(savedView)
                        ax.ZColor = 'none'; % Hide depth axis
                        ax.XColor = 'none'; % Hide perspective info
                    elseif strcmp(viewPoint, 'inferior')
                        savedView = [-90,-90];
                        view(savedView)
                        ax.YColor = 'none'; 
                        ax.ZColor = 'none';
                    elseif strcmp(viewPoint, 'posterior')
                        savedView = [0,0];
                        view(savedView)
                        ax.YColor = 'none'; 
                        ax.XColor = 'none';
                    end
    
                    if counter <= 2
                        title('Left Hemi')
                    end
                elseif strcmp(hemiName, 'rh')
                    if strcmp(viewPoint, 'lateral')
                        savedView = [90,0];
                        view(savedView)
                        ax.ZColor = 'none'; % Hide depth axis
                        ax.XColor = 'none'; % Hide perspective info
                    elseif strcmp(viewPoint, 'inferior')
                        savedView =[90,-90];
                        view(savedView)
                        ax.YColor = 'none'; 
                        ax.ZColor = 'none';
                    elseif strcmp(viewPoint, 'posterior')
                        savedView = [0,0];
                        view(savedView)
                        ax.YColor = 'none'; 
                        ax.XColor = 'none';
                    end
                    if counter <= 2
                        title('Right Hemi')
                    end
                end
                
                if ~strcmp(get(f, 'Renderer'), 'opengl')
                    % Convert 3D to 2D using the saved view
                    [az, el] = view(savedView);
                    V = viewmtx(az, el); % Get 4x4 projection matrix
                    vertices_2D = (V * [vertices, ones(size(vertices, 1), 1)]')';
    
                    % make the bins large enough to cover several vertices
                    % in the Z dimension
                    rounded_XY = round(vertices_2D(:, 1:2), -1);  % Round XY
    
                    % Find unique (rounded X, rounded Y) groups
                    [unique_XY, ~, group_ids] = unique(rounded_XY, 'rows');
                    
                    % Compute mean Z for each unique (X, Y)
                    mean_Z = accumarray(group_ids, vertices_2D(:,3), [], @mean);
                    mapped_mean_Z = mean_Z(group_ids); 
    
%                     max_Z = round(accumarray(group_ids, vertices_2D(:,3), [], @max));
%                     min_Z = round(accumarray(group_ids, vertices_2D(:,3), [], @min));
%                     midrange_Z = (max_Z + min_Z) / 500; % Compute center of range
%                     mapped_midrange_Z = midrange_Z(group_ids);
    
                    mask = vertices_2D(:,3) < mapped_mean_Z; %*(.8); %mean(mapped_mean_Z); %
                    %mask = vertices_2D(:,3) < mapped_midrange_Z; %mean(mapped_mean_Z); %
                    thresholded_data(mask) = nan; %
    
                    vertices_2D = vertices_2D(:, 1:2); % Keep only X and Y
    
                    figure(f)
                    subplot(numel(overlayNames),2,counter)
                    patch('Faces', faces, 'Vertices', vertices_2D, 'FaceVertexCData', thresholded_data, ... % Use thresholded data for coloring
                        'FaceColor', 'interp', 'EdgeColor', 'none');
                    colormap('jet')
                    colormap(custom_jet); % Use a colormap to represent magnitudes
                    caxis([curv_midpoints(1), max_thresh]);
                    axis off;
                    axis equal;
                end
    
                if counter == numel(views)*2
                    posBottomPlot = get(gca, 'Position');
                    bottomPlotPos = posBottomPlot(2);
                    colorbarPos = [0.2, bottomPlotPos-bottomPlotPos/2, 0.6, 0.3];
                    axJet = axes('Position', colorbarPos);
                    colormap(axJet, jet); % Use generic jet colormap
                    caxis([min_thresh max_thresh]); % Set range for generic jet
                    colorbar(axJet, 'Location', 'southoutside'); % Horizontal colorbar
                    axJet.Visible = 'off'; % Hide axes to keep only the colorbar
        
                    annotation('textbox', colorbarPos-[0 0.1 0 0], ... % [left, bottom, width, height] in figure coordinates
                        'String', 'PSC', ... % Your custom text
                        'HorizontalAlignment', 'center', ...
                        'VerticalAlignment', 'middle', ...
                        'FontSize', 12, ...
                        'EdgeColor', 'none'); % No box around the text
                end
    
                set(gcf, 'Color', 'w');
                counter = counter+1;
            end
        end
    
        sgtitle(strrep(overlayName, '_', ' '))
    
        % Force rendering before saving (increasing pause does not enhance
        % further)
        pause(1); drawnow;

        % save png
        imagePath = sprintf('%s', strrep(mgz_file, '.mgz', '.png'));
        [parentPath, fileName] = fileparts(imagePath);
        fileName = strrep(fileName, [hemiName, '.'], '');
    
        disp('Saving image..')
        
        exportgraphics(gcf, fullfile(parentPath, strcat(fileName, '.jpeg')), 'Resolution', 300);
        close all; 
    
    end

end
