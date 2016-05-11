require.config
    baseUrl: '/static/stacks/js/'
    waitSeconds: 200
    paths:
        jquery: 'library/jquery-1.9.1.min'
        text: 'library/text'
        handlebars: 'library/handlebars'
        underscore: 'library/underscore-min'
        backbone: 'library/backbone-min'
    shim:
        handlebars:
            exports: 'Handlebars'
        underscore:
            exports: '_'
        backbone:
            deps: ['underscore', 'jquery']
            exports: 'Backbone'

define (require, exports, module) ->
    $ = require 'jquery'
    Handlebars = require 'handlebars'
    Backbone = require 'backbone'
    menuTemplate = require 'text!templates/menu.handlebars'
    articleMenuTemplate = require 'text!templates/articlemenu.handlebars'
    publisherTemplate = require 'text!templates/publishers.handlebars'
    journalTemplate = require 'text!templates/journals.handlebars'
    volumeTemplate = require 'text!templates/volumes.handlebars'
    issueTemplate = require 'text!templates/issues.handlebars'
    journalDetail = require 'text!templates/journaldetail.handlebars'
    volumeDetail = require 'text!templates/volumedetail.handlebars'
    issueDetail = require 'text!templates/issuedetail.handlebars'
    titleTemplate = require 'text!templates/title.handlebars'
    pdfTemplate = require 'text!templates/pdf.handlebars'
    imageTemplate = require 'text!templates/image.handlebars'
    xmlTemplate = require 'text!templates/xml.handlebars'
    htmlTemplate = require 'text!templates/html.handlebars'
    paginatorTemplate = require 'text!templates/paginator.handlebars'

    Handlebars.registerHelper 'page_count', (index) ->
        index + 1

    # Models
    class Publisher extends Backbone.Model
        urlRoot: '/api/v1/stacks/publisher/'

    class Journal extends Backbone.Model
        urlRoot: '/api/v1/stacks/journal-expanded/'

    class Volume extends Backbone.Model
        urlRoot: '/api/v1/stacks/volume-expanded/'
        parse: (response) ->
            _.each response.orphan_files, (orphan) ->
                orphan.file_name = orphan.file_path.split('/').pop()
            return response

    class Issue extends Backbone.Model
        urlRoot: '/api/v1/stacks/issue-expanded/'
        parse: (response) ->
            _.each response.orphan_files, (orphan) ->
                orphan.file_name = orphan.file_path.split('/').pop()
            return response
    
    class Article extends Backbone.Model
        urlRoot: '/api/v1/stacks/article-expanded/'

    class File extends Backbone.Model
        urlRoot: '/api/v1/stacks/file/'

    # Collections
    class Publishers extends Backbone.Collection
        url: '/api/v1/stacks/publisher/'
        comparator: 'title'
        parse: (response) ->
            return response.objects

    class Journals extends Backbone.Collection
        url: '/api/v1/stacks/journal/'
        parse: (response) ->
            return response.objects

    class Volumes extends Backbone.Collection
        url: '/api/v1/stacks/volume/'
        parse: (response) ->
            return response.objects

    class VolumesOfJournal extends Backbone.Collection
        url: '/api/v1/stacks/volume/'
        parse: (response) ->
            return response.objects

    class IssuesOfVolume extends Backbone.Collection
        url: '/api/v1/stacks/issue/'
        parse: (response) ->
            return response.objects

    class Articles extends Backbone.Collection
        model: Article
        url: '/api/v1/stacks/article/'
        parse: (response) ->
            return response.objects

    class Files extends Backbone.Collection
        url: '/api/v1/stacks/file/'
        parse: (response) ->
            return response.objects

    # Views
    class PublisherList extends Backbone.View
        limit: 50
        events:
            'click .pager': 'paginate'
        paginate: (e) =>
            e.preventDefault()
            page = $(e.currentTarget).data('page')
            @render(page)
        initialize: ->
            $(@el).off 'click', '.pager'
            @render(0)
        render: (offset) ->
            publishers = new Publishers
            publishers.fetch
                data:
                    limit: @limit
                    offset: offset
                success: (publishers, @data) =>
                    template = Handlebars.compile(publisherTemplate)
                    $(@el).html(template(publishers: publishers.models))
                    eventAgg.trigger 'paginate', @data.meta.total_count, @limit
                    eventAgg.trigger 'titleUpdate', null
                    eventAgg.trigger 'menuUpdate', null
                beforeSend: ->
                    $('body').addClass('busybody')
                complete: ->
                    $('body').removeClass('busybody')
                error: (publishers, error) ->
                    eventAgg.trigger 'error', error

    class JournalSublist extends Backbone.View
        limit: 50
        events:
            'click .pager': 'paginate'
        paginate: (e) =>
            e.preventDefault()
            page = $(e.currentTarget).data('page')
            @render(page)
        initialize: ->
            $(@el).off 'click', '.pager'
            @render(0)
        render: (offset) ->
            journals = new Journals
            journals.fetch
                data:
                    limit: @limit
                    offset: offset
                    publishers: @options.publ
                success: (journals, @data) =>
                    publisher = new Publisher
                        id: @options.publ
                    publisher.fetch
                        success: (publisher) =>
                            publisherTitle = publisher.attributes.title
                            template = Handlebars.compile(journalTemplate)
                            $(@el).html(template(journals: journals.models, publisher: publisherTitle))
                            eventAgg.trigger 'paginate', @data.meta.total_count, @limit
                            eventAgg.trigger 'menuUpdate', null
                beforeSend: ->
                    $('body').addClass('busybody')
                complete: ->
                    $('body').removeClass('busybody')
                    $("html, body").animate({ scrollTop: 0}, "fast")
                error: (journals, error) ->
                    eventAgg.trigger 'error', error

    class JournalList extends Backbone.View
        limit: 50
        events:
            'click .pager': 'paginate'
        paginate: (e) =>
            e.preventDefault()
            page = $(e.currentTarget).data('page')
            @render(page)
        initialize: ->
            $(@el).off 'click', '.pager'
            @render(0)
        render: (offset) ->
            journals = new Journals
            journals.fetch
                data:
                    limit: @limit
                    offset: offset
                success: (journals, @data) =>
                    template = Handlebars.compile(journalTemplate)
                    $(@el).html(template(journals: journals.models))
                    eventAgg.trigger 'paginate', @data.meta.total_count, @limit
                    eventAgg.trigger 'titleUpdate', null
                    eventAgg.trigger 'menuUpdate', null
                beforeSend: ->
                    $('body').addClass('busybody')
                complete: ->
                    $('body').removeClass('busybody')
                    $("html, body").animate({ scrollTop: 0}, "fast")
                error: (journals, error) ->
                    eventAgg.trigger 'error', error

    class JournalDetail extends Backbone.View
        initialize: ->
            @render()
        render: ->
            journal = new Journal
                id: @options.journalID
            journal.fetch
                success: (journal) =>
                    journal.name = 'journal'
                    eventAgg.trigger 'titleUpdate', journal.attributes.full_title
                    eventAgg.trigger 'menuUpdate', journal
                    template = Handlebars.compile(journalDetail)
                    $(@el).html(template(journal: journal.attributes))
                beforeSend: ->
                    $('body').addClass('busybody')
                complete: ->
                    $('body').removeClass('busybody')
                error: (journal, error) ->
                    eventAgg.trigger 'error', error

    class VolumeDetail extends Backbone.View
        initialize: ->
            @render()
        render: ->
            volume = new Volume
                id: @options.volumeID
            volume.fetch
                success: (volume) =>
                    volume.name = 'volume'
                    _.each volume.attributes.orphan_articles, (item) ->
                        fileType = new FileType
                        file = fileType.determine(item.all_files)
                        if file.has_stylesheet
                            item.file_url = file.stacks_get_transform_url
                        else
                            item.file_url = file.stacks_get_absolute_url
                    orphanFiles = []
                    allowed = ['application/pdf', 'text/xml', 'text/html']
                    _.each volume.attributes.orphan_files, (orphan) ->
                        ext = orphan.file_format
                        if ext in allowed
                            if ext isnt 'text/xml'
                                orphan.file_url = orphan.stacks_get_absolute_url
                                orphanFiles.push(orphan)
                            else if orphan.has_stylesheet
                                orphan.file_url = orphan.stacks_get_transform_url
                                orphanFiles.push(orphan)
                    template = Handlebars.compile(volumeDetail)
                    $(@el).html(template(volume: volume.attributes, orphans: orphanFiles))
                    eventAgg.trigger 'titleUpdate', volume.attributes.journal.full_title
                    eventAgg.trigger 'menuUpdate', volume
                beforeSend: ->
                    $('body').addClass('busybody')
                complete: ->
                    $('body').removeClass('busybody')
                error: (volume, error) ->
                    eventAgg.trigger 'error', error

    class IssueDetail extends Backbone.View
        initialize: ->
            @render()
        render: ->
            issue = new Issue
                id: @options.issueID
            issue.fetch
                success: (issue) =>
                    issue.name = 'issue'
                    eventAgg.trigger 'titleUpdate', issue.attributes.journal.full_title
                    eventAgg.trigger 'menuUpdate', issue
                    _.each issue.attributes.articles, (item) ->
                        fileType = new FileType
                        file = fileType.determine(item.all_files)
                        if file.has_stylesheet
                            item.file_url = file.stacks_get_transform_url
                        else
                            item.file_url = file.stacks_get_absolute_url
                    orphanFiles = []
                    allowed = ['application/pdf', 'text/xml', 'text/html']
                    _.each issue.attributes.orphan_files, (orphan) ->
                        ext = orphan.file_format
                        if ext in allowed
                            if ext isnt 'text/xml'
                                orphan.file_url = orphan.stacks_get_absolute_url
                                orphanFiles.push(orphan)
                            else if orphan.has_stylesheet
                                orphan.file_url = orphan.stacks_get_transform_url
                                orphanFiles.push(orphan)
                    template = Handlebars.compile(issueDetail)
                    $(@el).html(template(issue: issue.attributes, orphans: orphanFiles))
                beforeSend: ->
                    $('body').addClass('busybody')
                complete: ->
                    $('body').removeClass('busybody')
                error: (issue, error) ->
                    eventAgg.trigger 'error', error

    class ArticleView extends Backbone.View
        initialize: =>
            $(@el).off 'click', '.pager'
            @render()
        render: =>
            article = new Article
                id: @options.articleID
            article.fetch
                beforeSend: ->
                    $('body').addClass('busybody')
                error: (article, error) ->
                    eventAgg.trigger 'error', error
                success: (article) =>
                    if article.attributes.issue?
                        issue = new Issue
                            id: article.attributes.issue.id
                        issue.fetch
                            beforeSend: ->
                                $('body').addClass('busybody')
                            complete: ->
                                $('body').removeClass('busybody')
                            error: (issue, error) ->
                                eventAgg.trigger 'error', error
                            success: (issue) =>
                                article_list = []
                                _.each issue.attributes.articles, (article) ->
                                    article_list.push article.id
                                article.index = $.inArray article.id, article_list
                                article.next = article_list[article.index + 1]
                                article.prev = article_list[article.index - 1]
                                article.nextIndex = article.index + 1
                                article.prevIndex = article.index - 1
                                article.name = 'article'
                                eventAgg.trigger 'titleUpdate', article.attributes.title
                                eventAgg.trigger 'menuUpdate', article
                                file_template = ''
                                fileType = new FileType
                                file = fileType.determine(article.attributes.all_files)
                                article.file_url = file.stacks_get_absolute_url
                                if file.file_format == 'application/pdf'
                                    file_template = pdfTemplate
                                else if file.file_format == 'text/xml'
                                    file_template = xmlTemplate
                                    article.file_url = file.stacks_get_transform_url
                                else if file.file_format == 'text/html'
                                    file_template = htmlTemplate
                                else
                                    file_template = imageTemplate
                                template = Handlebars.compile(file_template)
                                $(@el).html(template(article: article))
                    else if article.attributes.volume?
                        volume = new Volume
                            id: article.attributes.volume.id
                        volume.fetch
                            beforeSend: ->
                                $('body').addClass('busybody')
                            complete: ->
                                $('body').removeClass('busybody')
                            error: (issue, error) ->
                                eventAgg.trigger 'error', error
                            success: (volume) =>
                                article_list = []
                                _.each volume.attributes.orphan_articles, (article) ->
                                    article_list.push article.id
                                article.index = $.inArray article.id, article_list
                                article.next = article_list[article.index + 1]
                                article.prev = article_list[article.index - 1]
                                article.nextIndex = article.index + 1
                                article.prevIndex = article.index - 1
                                article.name = 'article'
                                eventAgg.trigger 'titleUpdate', article.attributes.title
                                eventAgg.trigger 'menuUpdate', article
                                file_template = ''
                                fileType = new FileType
                                file = fileType.determine(article.attributes.all_files)
                                article.file_url = file.stacks_get_absolute_url
                                if file.file_format == 'application/pdf'
                                    file_template = pdfTemplate
                                else if file.file_format == 'text/xml'
                                    file_template = xmlTemplate
                                    article.file_url = file.stacks_get_transform_url
                                else if file.file_format == 'text/html'
                                    file_template = htmlTemplate
                                else
                                    file_template = imageTemplate
                                template = Handlebars.compile(file_template)
                                $(@el).html(template(article: article))

    class OrphanView extends Backbone.View
        initialize: ->
            $(@el).off 'click', '.pager'
            @render()
        render: =>
            file = new File
                id: @options.fileID
            file.fetch
                beforeSend: ->
                    $('body').addClass('busybody')
                complete: ->
                    $('body').removeClass('busybody')
                error: (file, error) ->
                    eventAgg.trigger 'error', error
                success: (file) =>
                    if file.attributes.issues.length > 0
                        issueID = file.attributes.issues[0].id
                        issue = new Issue
                            id: issueID
                        issue.fetch
                            success: (issue) =>
                                file_list = []
                                allowed = ['application/pdf', 'text/xml', 'text/html']
                                _.each issue.attributes.orphan_files, (file) ->
                                    if file.file_format in allowed
                                        file_list.push file.id
                                file.index = $.inArray file.id, file_list
                                file.next = file_list[file.index + 1]
                                file.prev = file_list[file.index - 1]
                                file.nextIndex = file.index + 1
                                file.prevIndex = file.index - 1
                                file.name = 'file'
                                file_template = ''
                                file.file_url = file.attributes.stacks_get_absolute_url
                                ext = file.attributes.file_format
                                if ext == 'application/pdf'
                                    file_template = pdfTemplate
                                else if ext == 'text/xml'
                                    file_template = xmlTemplate
                                    file.file_url = file.attributes.stacks_get_transform_url
                                else if ext == 'text/html'
                                    file_template = htmlTemplate
                                template = Handlebars.compile(file_template)
                                $(@el).html(template(article: file)).show()
                                eventAgg.trigger 'menuUpdate', file
                    else if file.attributes.volumes.length > 0
                        volumeID = file.attributes.volumes[0].id
                        volume= new Volume
                            id: volumeID
                        volume.fetch
                            success: (volume) =>
                                file_list = []
                                allowed = ['application/pdf', 'text/xml', 'text/html']
                                _.each volume.attributes.orphan_files, (file) ->
                                    if file.file_format in allowed
                                        file_list.push file.id
                                file.index = $.inArray file.id, file_list
                                file.next = file_list[file.index + 1]
                                file.prev = file_list[file.index - 1]
                                file.nextIndex = file.index + 1
                                file.prevIndex = file.index - 1
                                file.name = 'file'
                                file_template = ''
                                file.file_url = file.attributes.stacks_get_absolute_url
                                ext = file.attributes.file_format
                                if ext == 'application/pdf'
                                    file_template = pdfTemplate
                                else if ext == 'text/xml'
                                    file_template = xmlTemplate
                                    file.file_url = file.attributes.stacks_get_transform_url
                                else if ext == 'text/html'
                                    file_template = htmlTemplate
                                template = Handlebars.compile(file_template)
                                $(@el).html(template(article: file)).show()
                                eventAgg.trigger 'menuUpdate', file

    # 'Helper' views, for areas of the page that are not specifically content. Navigation, pagination, etc.
    class Paginator extends Backbone.View
        el: '#stacks'
        render: (total_count, limit) ->
            if total_count > limit
                page_count = Math.ceil(total_count / limit)
                i = 0
                pages = while i < page_count
                    i++ * limit
                template = Handlebars.compile(paginatorTemplate)
                $('.pagination').html(template(pages: pages))

    paginator = new Paginator

    class Title extends Backbone.View
        render: (title) =>
            template = Handlebars.compile(titleTemplate)
            document.title = template(journal: title)

    title = new Title

    class Menu extends Backbone.View
        initialize: ->
            cookies = document.cookie.split('; ')
            _.each cookies, (cookie) ->
                crumb = cookie.split('=')
                if crumb[0] is 'lastpage'
                    window.location.hash = crumb[1]
                    document.cookie = 'lastpage=;expires=Thu, 01 Jan 1970 00:00:01 GMT;';
        el: '#left'
        events:
            'click .article_menu': 'showArticleMenu'
        showArticleMenu: (e) =>
            amenu = $('#nav_article_list,#menu_shim')
            e.preventDefault()
            e.stopPropagation()
            $('.article_menu').toggleClass('active')
            amenu.toggle()
            if amenu.is(':visible')
                amenu.on 'click', (e) ->
                    e.stopPropagation()
                $(document).on 'click', 'body', (e) =>
                    e.stopPropagation()
                    amenu.hide()
                    $('.article_menu').removeClass('active')
                    $(document).off 'click', 'body'
        render: (msg) =>
            if not msg?
                $('#left nav').empty()
            else
                lsgroup = false
                if $('body').data('edep-ls-group')
                    lsgroup = true
                if msg.attributes.journal?
                    multiple_publishers = if msg.attributes.journal.publishers.length > 1 then true else false
                else if msg.attributes.issues?
                    multiple_publishers = if msg.attributes.issues[0].journal.publishers.length > 1 then true else false
                else
                    multiple_publishers = if msg.attributes.publishers.length > 1 then true else false
                template = Handlebars.compile(menuTemplate)
                if msg.name == 'journal'
                    $('#left nav').html(template(multiple_publishers: multiple_publishers, journal: msg.attributes, lsgroup: lsgroup))
                if msg.name == 'volume'
                    $('#left nav').html(template(multiple_publishers: multiple_publishers, journal: msg.attributes.journal, volume: msg.attributes, lsgroup: lsgroup))
                    $('#nav_article_list').remove()
                    $('#menu_shim').remove()
                    comment = $('#content').contents().filter ->
                        return @nodeType == 8
                    comment.remove()
                    articleMenu = Handlebars.compile(articleMenuTemplate)
                    $('#left').after(articleMenu(volume: msg.attributes))
                if msg.name == 'issue'
                    $('#left nav').html(template(multiple_publishers: multiple_publishers, journal: msg.attributes.journal, volume: msg.attributes.volume, issue: msg.attributes, lsgroup: lsgroup))
                    $('#nav_article_list').remove()
                    $('#menu_shim').remove()
                    comment = $('#content').contents().filter ->
                        return @nodeType == 8
                    comment.remove()
                    articleMenu = Handlebars.compile(articleMenuTemplate)
                    $('#left').after(articleMenu(issue: msg.attributes))
                if msg.name == 'article'
                    $('#left nav').html(template(multiple_publishers: multiple_publishers, journal: msg.attributes.journal, volume: msg.attributes.volume, issue: msg.attributes.issue, article: msg.attributes, lsgroup: lsgroup))
                    $('#nav_article_list').remove()
                    $('#menu_shim').remove()
                    comment = $('#content').contents().filter ->
                        return @nodeType == 8
                    comment.remove()
                    articleMenu = Handlebars.compile(articleMenuTemplate)
                    $('#left').after(articleMenu(issue: msg.attributes.issue, volume: msg.attributes.volume))
                if msg.name == 'file'
                    $('#left nav').html(template(multiple_publishers: multiple_publishers, journal: msg.attributes.issues[0].journal, volume: msg.attributes.volumes[0], issue: msg.attributes.issues[0], article: msg.attributes.articles[0], lsgroup: lsgroup))
                    $('#nav_article_list').remove()
                    $('#menu_shim').remove()
                    comment = $('#content').contents().filter ->
                        return @nodeType == 8
                    comment.remove()
                    articleMenu = Handlebars.compile(articleMenuTemplate)
                    $('#left').after(articleMenu(issue: msg.attributes))

    menu = new Menu

    class FileType
        determine: (files) ->
            file = (item for item in files when item.file_format == 'application/pdf')
            if file.length < 1
                file = (item for item in files when item.file_format == 'text/xml')
                if file.length < 1
                    file = (item for item in files when item.file_format == 'text/html')
                    if file.length < 1
                        file = (item for item in files)
            return file[0]

    class ErrorHandler
        handle: (error) ->
            if error.status is 401
                document.cookie = 'lastpage=' + window.location.hash
                location.assign('/admin/?next=/stacks/')

    error = new ErrorHandler

    # Event aggregator
    class EventAggregator
        _.extend @prototype, Backbone.Events
    eventAgg = new EventAggregator
    eventAgg.on 'menuUpdate', menu.render
    eventAgg.on 'titleUpdate', title.render
    eventAgg.on 'paginate', paginator.render
    eventAgg.on 'error', error.handle

    # Router
    Stacks = Backbone.Router.extend
        routes:
            '': 'home'
            'publishers(/:publisher)': 'publishers'
            'journals': 'journals'
            'publisher/:publisher': 'publisher'
            'journals/:id': 'journalDetail'
            'volume/:volume': 'volumeDetail'
            'issue/:issue': 'issueDetail'
            'article/:article': 'article'
            'file/:file': 'file'
        home: ->
            new Menu
                el: '#stacks'
        publishers: ->
            new PublisherList
                el: '#stacks'
        journals: ->
            new JournalList
                el: '#stacks'
        publisher: (publisher) ->
            new JournalSublist
                el: '#stacks'
                publ: publisher
        journalDetail: (id) ->
            new JournalDetail
                el: '#stacks'
                journalID: id
        volumeDetail: (volume) ->
            new VolumeDetail
                el: '#stacks'
                volumeID: volume
        issueDetail: (issue) ->
            new IssueDetail
                el: '#stacks'
                issueID: issue
        article: (article) ->
            new ArticleView
                el: '#stacks'
                articleID: article
        file: (file) ->
            new OrphanView
                el: '#stacks'
                fileID: file

    stacks = new Stacks()

    stacks.on 'route', (e) ->
        if $('#nav_article_list').is(':visible')
            $('#nav_article_list,#menu_shim').hide()
            $('.article_menu').removeClass('active')

    Backbone.history.start()
