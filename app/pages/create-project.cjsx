React = require 'react'
Model = require '../lib/model'
apiClient = require '../api/client'
ChangeListener = require '../components/change-listener'
MarkdownEditor = require '../components/markdown-editor'
JSONEditor = require '../components/json-editor'
alert = require '../lib/alert'

MANIFEST_COLUMNS = [
  'original_width'
  'original_height'
  'title'
  'coord_0'
  'coord_1'
  'timestamp'
]

languages = ['en-us'] # TODO: Where should this live?

DEFAULT_TASKS =
  is_cool:
    type: 'single'
    question: 'Is this image cool?'
    answers: [{
      value: true
      label: 'Yes!'
    }, {
      value: false
      label: 'Nope'
    }]
    next: null

DEFAULT_DATA =
  language: languages[0]
  name: 'Something Zoo'
  introduction: 'Welcome to the Something Zoo'
  description: 'Here is a description.'
  scienceCase: 'Here is some science.'
  subjects: {}
  subjectManifest: null
  tasks: JSON.stringify DEFAULT_TASKS, null, 2

wizardData = new Model

refreshWizardData = ->
  wizardData.update JSON.parse JSON.stringify DEFAULT_DATA

refreshWizardData()

module.exports = React.createClass
  displayName: 'CreateProjectPage'

  render: ->
    <ChangeListener target={wizardData} handler={@renderWizard} />

  renderWizard: ->
    <div className="create-project-page">
      <div className="content-container">
        <h2>General information</h2>
        <fieldset>
          <legend>Project name</legend>
          <input type="text" name="name" placeholder="Project name" value={wizardData.name} onChange={@handleInputChange} style={width: '100%'} />
          <span /><div className="form-help">This will be used to identify your project across the site.</div>
        </fieldset>
        <fieldset>
          <legend>Introduction</legend>
          <input type="text" name="introduction" placeholder="A catchy slogan for the project" value={wizardData.introduction} onChange={@handleInputChange} style={width: '100%'} />
          <span /><div className="form-help">This will often be shown when a link on the site points to your project.</div>
        </fieldset>
        <fieldset>
          <legend>Project description</legend>
          <MarkdownEditor name="description" placeholder="Why is this project interesting?" value={wizardData.description} onChange={@handleInputChange} style={width: '100%'} />
          <span /><div className="form-help">Tell people why they should help with your project. What question are you trying to answer, and why is it important?</div>
        </fieldset>
      </div>

      <hr />

      <div className="content-container">
        <h2>Science case</h2>
        <fieldset>
          <MarkdownEditor name="scienceCase" placeholder="A more detailed explanation of what you hope to achieve with the data you collect" value={wizardData.scienceCase} onChange={@handleInputChange} />
          <span /><div className="form-help">Tell people how the data you collect will be used. What is the expected output of this project?</div>
        </fieldset>
      </div>

      <hr />

      <div className="content-container">
        <h2>Create a set of subjects</h2>
        <p>Now you’ll be able to choose the images you want volunteers to look at (JPEG, PNG, or GIF, please). Optionally, you can include metadata about the images with a manifest file <small>(TODO: describe the manifest)</small>.</p>
        <p>These images will be uploaded during after last step of this process, which could take a long time depending on how many you select. Make sure you’ve got a steady internet connection. You’ll have an opportunity to review and refine your selection here before continuing.</p>

        <table>
          <thead>
            <tr>
              <th></th>
              {<th>{column}</th> for column in MANIFEST_COLUMNS}
              <th></th>
            </tr>
          </thead>
          <tbody>
            {@_renderSubjectRows()}
          </tbody>
        </table>

        <p><input type="file" accept="image/*,text/tab-separated-values" multiple="multiple" onChange={@handleSubjectFilesSelection} /></p>
      </div>

      <hr />

      <div className="content-container">
        <h2>Define the classification workflow</h2>
        <p>Now you’ll define and link together the tasks each volunteer will do to complete a classification. <small>TODO: This is done in raw JSON for now.</small></p>
        <p className="form-help">Each task object gets a <code>type</code> of <code>single</code> or <code>multiple</code>, a <code>question</code> string, and an <code>answers</code> array. Each answer object gets a <code>value</code> and a <code>label</code>. TODO: describe type <code>drawing</code>.</p>
        <JSONEditor name="tasks" placeholder={JSON.stringify DEFAULT_TASKS, null, 2} value={wizardData.tasks} onChange={@handleInputChange} rows={20} cols={80} />
      </div>

      <hr />

      <div className="content-container">
        <h2>Review and complete</h2>
        <table>
          <tr>
            <td>{<i className="fa fa-check"></i> if wizardData.name and wizardData.introduction and wizardData.description}</td>
            <td>Name, introduction, description</td>
          </tr>
          <tr>
            <td>{<i className="fa fa-check"></i> if wizardData.scienceCase}</td>
            <td>Science case</td>
          </tr>
          <tr>
            <td>{Object.keys(wizardData.subjects).length}</td>
            <td>Subjects</td>
          </tr>
          <tr>
            <td>{try Object.keys(JSON.parse wizardData.tasks).length catch then <i className="fa fa-times form-help error"></i>}</td>
            <td>Workflow tasks</td>
          </tr>
        </table>

        <p><button type="submit" onClick={@handleSubmit}>Create project and upload subject images</button></p>
      </div>
    </div>

  _renderSubjectRows: ->
    subjectsInOrder = []

    if wizardData.subjectManifest?
      for filename, metadata of wizardData.subjectManifest when filename not of wizardData.subjects
        subjectsInOrder.push {filename, metadata}
      for filename, metadata of wizardData.subjects when filename not of wizardData.subjectManifest
        subjectsInOrder.push {filename, metadata}
      for filename, metadata of wizardData.subjectManifest when filename of wizardData.subjects
        subjectsInOrder.push {filename, metadata}

    else
      for filename, metadata of wizardData.subjects
        subjectsInOrder.push {filename, metadata}

    @_renderSubjectRow filename, metadata for {filename, metadata} in subjectsInOrder

  _renderSubjectRow: (filename, metadata) ->
    missing = wizardData.subjectManifest? and filename not of wizardData.subjects
    notInManifest = wizardData.subjectManifest? and filename not of wizardData.subjectManifest

    style = if missing
      background: 'rgba(255, 0, 0, 0.2)'
      color: 'red'
    else if notInManifest
      background: 'rgba(255, 255, 0, 0.2)'

    <tr key={filename} style={style}>
      <td>
        {filename}
        {<div className="form-help"><i className="fa fa-exclamation-circle"></i> In manifest, missing image</div> if missing}
        {<div className="form-help"><i className="fa fa-exclamation-triangle"></i> Not in manifest</div> if notInManifest}
      </td>

      {<td>{metadata[column] ? <span className="form-help">?</span>}</td> for column in MANIFEST_COLUMNS}

      <td>
        {<button onClick={@removeSubject.bind this, filename}><i className="fa fa-times"></i></button> unless missing}
      </td>
    </tr>

  handleInputChange: (e) ->
    valueProperty = switch e.target.type
      when 'radio', 'checkbox' then 'checked'
      when 'file' then 'files'
      else 'value'

    changes = {}
    changes[e.target.name] = e.target[valueProperty]

    wizardData.update changes

  removeSubject: (filename) ->
    delete wizardData.subjects[filename]

    if wizardData.subjectManifest?
      delete wizardData.subjectManifest[filename]

    @forceUpdate()

  handleSubjectFilesSelection: (e) ->
    manifest = null
    images = {}

    for file in e.target.files
      if file.type is 'text/tab-separated-values'
        manifest = file
      else if file.type.indexOf 'image' is 0
        images[file.name] = file

    wizardData.update subjects: images

    if manifest?
      @_setManifest manifest
    else
      wizardData.update subjectManifest: null

  _setManifest: (file) ->
    reader = new FileReader
    files = {}

    reader.onload = ->
      for line in reader.result.split '\n' when line
        [filename, original_width, original_height, title, coord_0, coord_1, timestamp] = line.split '\t'
        files[filename] = {original_width, original_height, title, coord_0, coord_1, timestamp}

      wizardData.update subjectManifest: files

    reader.readAsText file

  handleSubmit: ->
    # projectData = JSON.parse JSON.stringify wizardData
    # project = apiClient.createType('projects').createResource projectData
    # project.save()
    #   .then (project) ->
    #     workflowData = JSON.parse JSON.stringify newWorkflowData
    #     workflowData.tasks = JSON.parse workflowData.tasks
    #     workflowData.links = project: project.id
    #     workflow = apiClient.createType('workflows').createResource workflowData
    #     workflow.save()
    #       .then (workflow) =>
    #         console?.info 'Saved a project and a workflow', project, workflow
    #         # location.hash = '/build/edit-project/' + project.id

    #       .catch (errors) ->
    #         alert <p>Error saving workflow:<br /><code>{errors}</code></p>

    #   .catch (errors) ->
    #     alert <p>Error saving project:<br /><code>{errors}</code></p>
